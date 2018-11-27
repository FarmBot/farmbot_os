defmodule Farmbot.Target.Network do
  @moduledoc "Manages Network Connections"
  use GenServer
  require Logger

  alias Nerves.NetworkInterface
  import Farmbot.Target.Network.Utils

  @validation_ms 30_000

  defmodule State do
    @moduledoc false
    defstruct ifnames: [],
              config: %{},
              hostap: :down,
              hostap_dhcp_server_pid: nil,
              hostap_wpa_supplicant_pid: nil
  end

  @doc "List all ifnames the Network Manager knows about."
  def ifnames do
    GenServer.call(__MODULE__, :ifnames)
  end

  @doc "Bring down hostap, bring up networking. Will reset if not `validate/0`d in time."
  def setup(ifname, opts) do
    GenServer.cast(__MODULE__, {:setup, ifname, opts})
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
      Nerves.NetworkInterface.ifdown(ifname)
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
      Nerves.Network.setup(ifname, conf)
    end

    {:noreply, %{state | hostap: :pending_validation}, @validation_ms}
  end

  def stop_hostap(%{hostap: :up} = state) do
    state = try_stop_dhcp(state)
    Nerves.Network.teardown("wlan0")
    Nerves.Network.setup("wlan0", [])
    Nerves.NetworkInterface.setup("wlan0", [])
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

    dhcp_opts = [
      gateway: "192.168.24.1",
      netmask: "255.255.255.0",
      range: {"192.168.24.2", "192.168.24.10"},
      domain_servers: ["192.168.24.1"]
    ]

    Nerves.Network.teardown("wlan0")
    Nerves.Network.setup("wlan0", hostap_opts)
    Nerves.NetworkInterface.setup("wlan0", ip_opts)
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
