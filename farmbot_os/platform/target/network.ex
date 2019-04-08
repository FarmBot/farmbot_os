defmodule FarmbotOS.Platform.Target.Network do
  @moduledoc "Manages Network Connections"
  use GenServer
  require Logger

  alias Nerves.NetworkInterface
  import FarmbotOS.Platform.Target.Network.Utils
  alias FarmbotCore.Config

  @validation_ms 30_000

  defmodule State do
    @moduledoc false
    defstruct ifnames: [],
              config: %{},
              hostap: :down,
              hostap_dhcp_server_pid: nil,
              hostap_wpa_supplicant_pid: nil
  end

  def reload do
    for %{name: ifname} = settings <- Config.get_all_network_configs() do
      settings = validate_settings(settings)
      Logger.warn("Trying to configure #{ifname}: #{inspect(settings)}")
      setup(ifname, settings)
    end
  end

  def validate_settings(%{type: "wired"} = settings) do
    validate_advanced(settings)
  end

  def validate_settings(settings) do
    ssid = Map.fetch!(settings, :ssid)
    psk = Map.fetch!(settings, :psk)

    key_mgmt =
      case Map.fetch!(settings, :security) do
        "WPA-PSK" -> :"WPA-PSK"
        "WPA2-PSK" -> :"WPA-PSK"
        "WPA-EAP" -> :"WPA-EAP"
        "NONE" -> :NONE
      end

    config =
      [
        ssid: ssid,
        psk: psk,
        key_mgmt: key_mgmt,
        scan_ssid: 1
      ] ++ validate_eap(settings) ++ validate_advanced(settings)

    [networks: [config]]
  end

  def validate_eap(%{security: "WPA-EAP"} = settings) do
    identity = Map.fetch!(settings, :identity)
    password = Map.fetch!(settings, :password)

    [
      pairwise: :"CCMP TKIP",
      group: :"CCMP TKIP",
      eap: :PEAP,
      identity: identity,
      password: password,
      phase1: "peapver=auto",
      phase2: "MSCHAPV2"
    ]
  end

  def validate_eap(%{} = _settings) do
    []
  end

  def validate_advanced(%{ipv4_address: "static"} = settings) do
    [
      ipv4_address_method: :static,
      ipv4_address: Map.fetch!(settings, :ipv4_address),
      ipv4_gateway: Map.fetch!(settings, :ipv4_gateway),
      ipv4_subnet_mask: Map.fetch!(settings, :ipv4_subnet_mask),
      nameservers: String.split(settings.name_servers, " ")
    ]
  end

  def validate_advanced(%{ipv4_method: _} = _settings) do
    []
  end

  def list_interfaces do
    ifnames()
    |> List.delete("lo")
    |> Enum.map(fn ifname ->
      {:ok, settings} = NetworkInterface.settings(ifname)
      {ifname, settings}
    end)
  end

  @doc "List all ifnames the Network Manager knows about."
  def ifnames do
    GenServer.call(__MODULE__, :ifnames)
  end

  @doc "Bring down hostap, bring up networking. Will reset if not `validate/0`d in time."
  def setup(ifname, settings) do
    GenServer.cast(__MODULE__, {:setup, ifname, settings})
  end

  @doc "Validate the config given to the Network manager"
  def validate do
    GenServer.cast(__MODULE__, :validate)
  end

  @doc "Bring down networking, bring up hostap"
  def hostap_up do
    GenServer.cast(__MODULE__, :hostap_up)
  end

  @doc "Bring down hostap, Bring up networking"
  def hostap_down do
    GenServer.cast(__MODULE__, :hostap_down)
  end

  @doc "Start the Network manager."
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    config = Keyword.get(args, :config, %{})
    {:ok, %State{config: config}, 0}
  end

  def terminate(_, state) do
    state = try_stop_dhcp(state)

    for ifname <- state.ifnames do
      Nerves.Network.teardown(ifname)
    end
  end

  def handle_call(:ifnames, _from, state) do
    {:reply, state.ifnames, state}
  end

  def handle_cast({:setup, ifname, opts}, state) do
    {:noreply, %{state | config: Map.put(state.config, ifname, opts)}, 0}
  end

  def handle_cast(:hostap_up, state) do
    setup_hostap(state)
  end

  def handle_cast(:hostap_down, state) do
    {:noreply, stop_hostap(state), 0}
  end

  def handle_cast(:validate, state) do
    Logger.info("Config validated")
    {:noreply, %{state | hostap: :validated}}
  end

  def handle_info(:timeout, %{ifnames: []} = state) do
    Logger.info("Detecting ifnames")
    ifnames = NetworkInterface.interfaces()
    {:noreply, %{state | ifnames: ifnames}, 0}
  end

  def handle_info(:timeout, %{config: c} = state) when map_size(c) == 0 do
    setup_hostap(state)
  end

  def handle_info(:timeout, %{hostap: :pending_validation} = state) do
    Logger.warn("Config not validated in time.")
    setup_hostap(%{state | config: %{}})
  end

  def handle_info(:timeout, state) do
    Logger.info("Waiting #{@validation_ms} ms for config to be validated.")
    state = stop_hostap(state)

    for {ifname, conf} <- state.config do
      Logger.debug("Nerves.Network.setup(#{inspect(ifname)}, #{inspect(conf)}")
      Nerves.Network.setup(ifname, conf)
    end

    {:noreply, %{state | hostap: :pending_validation}, @validation_ms}
  end

  def stop_hostap(%{hostap: :up} = state) do
    state = try_stop_dhcp(state)

    for {ifname, _conf} <- state.config do
      Logger.info("Stopping hostap")
      Nerves.Network.teardown(ifname)
      Nerves.Network.setup(ifname, [])
    end

    %{state | hostap: :down, hostap_wpa_supplicant_pid: nil}
  end

  # hostap down or not available.
  def stop_hostap(state), do: state

  def setup_hostap(%{hostap: :up} = state), do: {:noreply, state}

  def setup_hostap(state) do
    hostap_opts = [
      ssid: build_hostap_ssid(),
      key_mgmt: :NONE,
      mode: 2
    ]

    ip_opts = [
      ipv4_address_method: :static,
      ipv4_address: "192.168.24.1",
      ipv4_gateway: "192.168.24.1",
      ipv4_subnet_mask: "255.255.0.0",
      nameservers: ["192.168.24.1"]
    ]

    network_opts = [
      networks: [hostap_opts ++ ip_opts]
    ]

    dhcp_opts = [
      gateway: "192.168.24.1",
      netmask: "255.255.255.0",
      range: {"192.168.24.2", "192.168.24.10"},
      domain_servers: ["192.168.24.1"]
    ]

    Nerves.Network.teardown("wlan0")
    Nerves.Network.setup("wlan0", network_opts)
    {:ok, hostap_dhcp_server_pid} = DHCPServer.start_link("wlan0", dhcp_opts)
    {:ok, hostap_wpa_supplicant_pid} = wait_for_wpa("wlan0")

    {:noreply,
     %{
       state
       | hostap: :up,
         hostap_dhcp_server_pid: hostap_dhcp_server_pid,
         hostap_wpa_supplicant_pid: hostap_wpa_supplicant_pid
     }}
  end

  defp wait_for_wpa(ifname) do
    # Logger.debug("waiting for #{ifname} wpa_supplicant")
    name = :"Nerves.WpaSupplicant.#{ifname}"

    case GenServer.whereis(name) do
      nil -> wait_for_wpa(ifname)
      pid -> {:ok, pid}
    end
  end

  defp try_stop_dhcp(state) do
    if state.hostap_dhcp_server_pid && Process.alive?(state.hostap_dhcp_server_pid) do
      Logger.debug("Stopping DHCP Server")
      GenServer.stop(state.hostap_dhcp_server_pid, :normal)
    end

    %{state | hostap_dhcp_server_pid: nil}
  end
end
