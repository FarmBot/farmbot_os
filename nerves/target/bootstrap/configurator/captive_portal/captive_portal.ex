defmodule Farmbot.Target.Bootstrap.Configurator.CaptivePortal do
  use GenServer
  use Farmbot.Logger

  @interface Application.get_env(:farmbot, :captive_portal_interface, "wlan0")
  @address Application.get_env(:farmbot, :captive_portal_address, "192.168.25.1")
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    Logger.busy(3, "Starting captive portal.")
    {:ok, hostapd} = Hostapd.start_link(interface: @interface, address: @address)
    dhcp_opts = [
      gateway: @address,
      netmask: "255.255.255.0",
      range: {dhcp_range_begin(@address), dhcp_range_end(@address)},
      domain_servers: [@address],
    ]
    {:ok, dhcp_server} = DHCPServer.start_link(@interface, dhcp_opts)
    {:ok, %{hostapd: hostapd, dhcp_server: dhcp_server}}
  end

  def terminate(_, state) do
    Logger.busy 3, "Stopping captive portal GenServer."
    Logger.busy 3, "Stopping DHCP GenServer."
    GenServer.stop(state.dhcp_server, :normal)
    Logger.busy 3, "Stopping Hostapd GenServer."
    GenServer.stop(state.hostapd, :normal)
  end

  defp dhcp_range_begin(address) do
    [a, b, c, _] = String.split(address, ".")
    Enum.join([a, b, c, "2"], ".")
  end

  defp dhcp_range_end(address) do
    [a, b, c, _] = String.split(address, ".")
    Enum.join([a, b, c, "10"], ".")
  end
end
