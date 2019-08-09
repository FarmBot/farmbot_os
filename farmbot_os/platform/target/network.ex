defmodule FarmbotOS.Platform.Target.Network do
  @moduledoc "Manages Network Connections"
  use GenServer, shutdown: 10_000
  require Logger
  require FarmbotCore.Logger

  import FarmbotOS.Platform.Target.Network.Utils,
    only: [
      maybe_hack_tzdata: 0,
      init_net_kernel: 0,
      build_hostap_ssid: 0
    ]

  alias FarmbotOS.Platform.Target.Network.PreSetup
  alias FarmbotOS.Platform.Target.Configurator.{Validator, CaptivePortal}
  alias FarmbotCore.{Asset, Config, Leds}

  @default_network_not_found_timer_minutes 20

  def host do
    %{
      type: CaptivePortal,
      wifi: %{
        ssid: build_hostap_ssid(),
        mode: :host,
        key_mgmt: :none
      },
      ipv4: %{
        method: :static,
        address: "192.168.24.1",
        netmask: "255.255.255.0"
      },
      dnsmasq: %{
        domain: "farmbot",
        server: "192.168.24.1",
        address: "192.168.24.1",
        start: "192.168.24.2",
        end: "192.168.24.10"
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
    # email = Config.get_config_value(:string, "authorization", "email")
    # password = Config.get_config_value(:string, "authorization", "password")
    # server = Config.get_config_value(:string, "authorization", "server")
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

  def handle_info({VintageNet, ["interface", ifname, "type"], _old, type, _meta}, state)
      when type in [PreSetup, VintageNet.Technology.Null] do
    FarmbotCore.Logger.debug(1, "Network interface needs configuration: #{ifname}")

    case Config.get_network_config(ifname) do
      %Config.NetworkInterface{} = config ->
        FarmbotCore.Logger.busy(3, "Setting up network interface: #{ifname}")

        case reset_ntp() do
          :ok ->
            :ok

          error ->
            FarmbotCore.Logger.error(1, """
            Failed to configure NTP: #{inspect(error)}
            """)
        end

        vintage_net_config = to_vintage_net(config)
        configure_result = VintageNet.configure(config.name, vintage_net_config)

        FarmbotCore.Logger.success(3, "#{config.name} setup: #{inspect(configure_result)}")

        state = start_network_not_found_timer(state)
        {:noreply, state}

      nil ->
        {:noreply, state}
    end
  end

  def handle_info({VintageNet, ["interface", ifname, "lower_up"], _old, false, _meta}, state) do
    FarmbotCore.Logger.error(1, "Interface #{ifname} disconnected from access point")
    state = start_network_not_found_timer(state)
    {:noreply, state}
  end

  def handle_info({VintageNet, ["interface", ifname, "lower_up"], _old, true, _meta}, state) do
    FarmbotCore.Logger.success(1, "Interface #{ifname} connected access point")
    state = cancel_network_not_found_timer(state)
    {:noreply, state}
  end

  def handle_info(
        {VintageNet, ["interface", ifname, "connection"], :disconnected, :lan, _meta},
        state
      ) do
    FarmbotCore.Logger.warn(1, "Interface #{ifname} connected to local area network")
    {:noreply, state}
  end

  def handle_info(
        {VintageNet, ["interface", ifname, "connection"], :lan, :internet, _meta},
        state
      ) do
    FarmbotCore.Logger.warn(1, "Interface #{ifname} connected to internet")
    state = cancel_network_not_found_timer(state)
    {:noreply, %{state | first_connect?: false}}
  end

  def handle_info(
        {VintageNet, ["interface", ifname, "connection"], :internet, ifstate, _meta},
        state
      ) do
    FarmbotCore.Logger.warn(1, "Interface #{ifname} disconnected from the internet: #{ifstate}")
    FarmbotExt.AMQP.ConnectionWorker.close()

    if state.network_not_found_timer do
      {:noreply, state}
    else
      state = start_network_not_found_timer(state)
      {:noreply, state}
    end
  end

  def handle_info(
        {VintageNet, ["interface", _, "wifi", "access_points"], _old, _new, _meta},
        state
      ) do
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
    FarmbotCore.Logger.warn(1, """
    Farmbot has been disconnected from the network for 
    #{minutes} minutes. Going down for factory reset.
    """)

    FarmbotOS.System.factory_reset("""
    Farmbot has been disconnected from the network for 
    #{minutes} minutes.
    """)

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
    FarmbotCore.Logger.success(
      1,
      "Farmbot has been reconnected. Canceling scheduled factory reset"
    )

    old_timer = state.network_not_found_timer
    old_timer && Process.cancel_timer(old_timer)
    %{state | network_not_found_timer: nil}
  end

  defp start_network_not_found_timer(state) do
    state = cancel_network_not_found_timer(state)
    # Stored in minutes
    minutes = network_not_found_timer_minutes(state)
    millis = minutes * 60000
    new_timer = Process.send_after(self(), {:network_not_found_timer, minutes}, millis)

    FarmbotCore.Logger.warn(1, """
    FarmBot will factory reset in #{minutes} minutes if the network does not 
    reassociate. 
    If you see this message directly after configuration, this message can be safely ignored.
    """)

    %{state | network_not_found_timer: new_timer}
  end

  # if the network has never connected before, make a low
  # thresh so that user won't have to wait 20 minutes to reconfigurate
  # due to bad wifi credentials.
  defp network_not_found_timer_minutes(%{first_connect?: true}), do: 1

  defp network_not_found_timer_minutes(_state) do
    Asset.fbos_config(:network_not_found_timer) || @default_network_not_found_timer_minutes
  end

  def reset_ntp do
    ntp_server_1 = Config.get_config_value(:string, "settings", "default_ntp_server_1")
    ntp_server_2 = Config.get_config_value(:string, "settings", "default_ntp_server_2")

    if ntp_server_1 || ntp_server_2 do
      Logger.info("Setting NTP servers: [#{ntp_server_1}, #{ntp_server_2}]")

      [ntp_server_1, ntp_server_2]
      |> Enum.reject(&is_nil/1)
      |> Nerves.Time.set_ntp_servers()
    else
      Logger.info("Using default NTP servers")
      :ok
    end
  end
end
