defmodule FarmbotOS.Platform.Target.Network do
  @moduledoc "Manages Network Connections"

  use GenServer, shutdown: 10_000
  require Logger
  require FarmbotTelemetry

  import FarmbotOS.Platform.Target.Network.Utils,
    only: [
      maybe_hack_tzdata: 0,
      init_net_kernel: 0,
      build_hostap_ssid: 0
    ]

  alias FarmbotOS.Platform.Target.Network.PreSetup
  alias FarmbotOS.Platform.Target.Configurator.{Validator, CaptivePortal}
  alias FarmbotOS.{Asset, Config, Leds}

  @default_network_not_found_timer_minutes 999_999

  def host do
    me = "192.168.24.1"
    me_but_tuple = {192, 168, 24, 1}

    %{
      type: CaptivePortal,
      vintage_net_wifi: %{
        networks: [
          %{
            ssid: build_hostap_ssid(),
            mode: :ap,
            key_mgmt: :none
          }
        ]
      },
      ipv4: %{
        method: :static,
        address: me,
        netmask: "255.255.255.0"
      },
      dhcpd: %{
        options: %{
          dns: [me],
          router: [me],
          subnet: {255, 255, 255, 0}
        },
        start: "192.168.24.2",
        end: "192.168.24.10"
      },
      dnsd: %{
        records: [
          {"*", me_but_tuple},
          {"setup.farm.bot", me_but_tuple}
        ]
      }
    }
  end

  def null do
    %{type: VintageNet.Technology.Null}
  end

  def presetup do
    %{type: PreSetup}
  end

  def is_first_connect?() do
    token = Config.get_config_value(:string, "authorization", "token")
    is_nil(token)
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init(_args) do
    _ = maybe_hack_tzdata()
    _ = init_net_kernel()
    send(self(), :setup)
    # If a secret exists, assume that
    # farmbot at one point has been connected to the internet
    first_connect? = is_first_connect?()

    if first_connect? do
      _ = Leds.blue(:slow_blink)
      :ok = VintageNet.configure("wlan0", null())
      Process.sleep(1500)
      :ok = VintageNet.configure("wlan0", host())
    end

    {:ok, %{network_not_found_timer: nil, first_connect?: first_connect?}}
  end

  @impl GenServer
  def terminate(_, _) do
    :ok = VintageNet.configure("wlan0", null())
    :ok = VintageNet.configure("eth0", null())
  end

  @impl GenServer
  def handle_info(:setup, state) do
    configs = Config.get_all_network_configs()

    case configs do
      [] ->
        Process.send_after(self(), :setup, 5_000)
        {:noreply, state}

      _ ->
        _ = VintageNet.subscribe(["interface", "wlan0"])
        _ = VintageNet.subscribe(["interface", "eth0"])
        :ok = VintageNet.configure("wlan0", presetup())
        :ok = VintageNet.configure("eth0", presetup())
        Process.sleep(1500)
        {:noreply, state}
    end
  end

  def handle_info(
        {VintageNet, ["interface", ifname, "type"], _old, type, _meta},
        state
      )
      when type in [PreSetup, VintageNet.Technology.Null] do
    Logger.debug("Network interface needs configuration: #{ifname}")

    case Config.get_network_config(ifname) do
      %Config.NetworkInterface{} = config ->
        Logger.debug("Setting up network interface: #{ifname}")

        case reset_ntp() do
          :ok ->
            :ok

          error ->
            Logger.error("Failed to configure NTP: #{inspect(error)}")
        end

        vintage_net_config = to_vintage_net(config)
        Logger.info(inspect(vintage_net_config))

        FarmbotTelemetry.event(:network, :interface_configure, nil,
          interface: ifname
        )

        configure_result = VintageNet.configure(config.name, vintage_net_config)

        Logger.debug("#{config.name} setup: #{inspect(configure_result)}")

        state = start_network_not_found_timer(state)
        {:noreply, state}

      nil ->
        {:noreply, state}
    end
  end

  def handle_info(
        {VintageNet, ["interface", ifname, "lower_up"], _old, false, _meta},
        state
      ) do
    Logger.debug("Interface #{ifname} disconnected from access point")

    FarmbotTelemetry.event(:network, :interface_disconnect, nil,
      interface: ifname
    )

    state = start_network_not_found_timer(state)
    {:noreply, state}
  end

  def handle_info(
        {VintageNet, ["interface", ifname, "lower_up"], _old, true, _meta},
        state
      ) do
    Logger.debug("Interface #{ifname} connected access point")
    FarmbotTelemetry.event(:network, :interface_connect, nil, interface: ifname)
    state = cancel_network_not_found_timer(state)
    {:noreply, state}
  end

  def handle_info(
        {VintageNet, ["interface", ifname, "connection"], :disconnected, :lan,
         _meta},
        state
      ) do
    Logger.debug("Interface #{ifname} connected to local area network")

    FarmbotTelemetry.event(:network, :lan_connect, nil, interface: ifname)
    {:noreply, state}
  end

  def handle_info(
        {VintageNet, ["interface", ifname, "connection"], :lan, :internet,
         _meta},
        state
      ) do
    Logger.debug("Interface #{ifname} connected to internet")
    state = cancel_network_not_found_timer(state)
    FarmbotTelemetry.event(:network, :wan_connect, nil, interface: ifname)
    {:noreply, %{state | first_connect?: false}}
  end

  def handle_info(
        {VintageNet, ["interface", ifname, "connection"], :internet, ifstate,
         _meta},
        state
      ) do
    Logger.warn(
      "Interface #{ifname} disconnected from the internet: #{ifstate}"
    )

    FarmbotTelemetry.event(:network, :wan_disconnect, nil, interface: ifname)

    if state.network_not_found_timer do
      {:noreply, state}
    else
      state = start_network_not_found_timer(state)
      {:noreply, state}
    end
  end

  def handle_info(
        {VintageNet, ["interface", _, "wifi", "access_points"], _old, _new,
         _meta},
        state
      ) do
    {:noreply, state}
  end

  def handle_info(
        {VintageNet, ["interface", _ifname, "eap_status"], _old,
         %{status: :success} = eap_status, _meta},
        state
      ) do
    Logger.debug("Farmbot successfully completed EAP Authentication.
    #{inspect(eap_status, limit: :infinity)}")

    {:noreply, state}
  end

  def handle_info(
        {VintageNet, ["interface", _ifname, "eap_status"], _old,
         %{status: :failure}, _meta},
        state
      ) do
    Logger.error("""
    Farmbot was unable to associate with the EAP network.
    Please check the identity, password and method of connection
    """)

    FarmbotOS.System.factory_reset("""
    Farmbot was unable to associate with the EAP network.
    Please check the identity, password and method of connection
    """)

    {:noreply, state}
  end

  def handle_info({VintageNet, property, old, new, _meta}, state) do
    Logger.debug("""
    Unknown property change: #{inspect(property)}
    old:

    #{inspect(old, limit: :infinity)}

    new:

    #{inspect(new, limit: :infinity)}
    """)

    {:noreply, state}
  end

  def handle_info({:network_not_found_timer, minutes}, state) do
    Logger.warn("""
    Farmbot has been disconnected from the network for
    #{minutes} minutes.
    """)

    first_connect? = is_first_connect?()

    if first_connect? do
      FarmbotOS.System.set_shutdown_reason("""
      FarmBot could not connect to the network. Please double check cable
      connectivity using another device and try again. Are you sure it is
      spelled correctly, in range, and has Good or Okay signal strength?
      If your signal is too weak, consider using a WiFi repeater or an
      Ethernet connection. Please try again and use the eye icon to double
      check you have typed the password correctly. FarmBot requires ports 80,
      443, 3002, and 8883 to communicate with the web app servers.
      Please contact your network administrator to ensure all of these ports
      are open for the FarmBot.
      """)
    end

    {:noreply, state}
  end

  def to_vintage_net(%Config.NetworkInterface{} = config) do
    %{
      type: Validator,
      network_type: config.type,
      ssid: config.ssid,
      security: config.security,
      psk: config.psk,
      identity: config.identity,
      password: config.password,
      domain: config.domain,
      name_servers: config.name_servers,
      ipv4_method: config.ipv4_method,
      ipv4_address: config.ipv4_address,
      ipv4_gateway: config.ipv4_gateway,
      ipv4_subnet_mask: config.ipv4_subnet_mask,
      regulatory_domain: config.regulatory_domain
    }
  end

  defp cancel_network_not_found_timer(state) do
    old_timer = state.network_not_found_timer
    FarmbotOS.Time.cancel_timer(old_timer)
    %{state | network_not_found_timer: nil}
  end

  defp start_network_not_found_timer(state) do
    state = cancel_network_not_found_timer(state)
    # Stored in minutes
    minutes = network_not_found_timer_minutes(state)
    millis = minutes * 60000

    new_timer =
      Process.send_after(self(), {:network_not_found_timer, minutes}, millis)

    %{state | network_not_found_timer: new_timer}
  end

  # if the network has never connected before, make a low
  # thresh so that user won't have to wait 20 minutes to reconfigurate
  # due to bad wifi credentials.
  defp network_not_found_timer_minutes(%{first_connect?: true}), do: 1

  defp network_not_found_timer_minutes(_state) do
    Asset.fbos_config(:network_not_found_timer) ||
      @default_network_not_found_timer_minutes
  end

  def reset_ntp do
    FarmbotTelemetry.event(:ntp, :reset)

    ntp_server_1 =
      Config.get_config_value(:string, "settings", "default_ntp_server_1")

    ntp_server_2 =
      Config.get_config_value(:string, "settings", "default_ntp_server_2")

    if ntp_server_1 || ntp_server_2 do
      Logger.info("Setting NTP servers: [#{ntp_server_1}, #{ntp_server_2}]")

      [ntp_server_1, ntp_server_2]
      |> Enum.reject(&is_nil/1)
      |> NervesTime.set_ntp_servers()
    else
      Logger.info("Using default NTP servers")
      :ok
    end
  end
end
