defmodule Farmbot.Target.Network do
  @moduledoc "Bring up network."

  @behaviour Farmbot.System.Init
  alias Farmbot.System.ConfigStorage
  alias ConfigStorage.NetworkInterface
  use Supervisor
  require Logger

  defmodule NetworkWatcher do
    use GenServer

    def start_link(name) do
      GenServer.start_link(__MODULE__, name, name: :"network_interface_#{name}")
    end

    def init(name) do
      SystemRegistry.register()
      {:ok, %{name: name, connected: false}}
    end

    def handle_info({:system_registry, :global, registry}, state) do
      _status = get_in registry, [:state, :network_interface, state.name]

      connected = match?({:ok, {:hostent, 'nerves-project.org', [], :inet, 4, _}}, test_dns())
      {:noreply, %{state | connected: connected}}
    end

    def test_dns(hostname \\ 'nerves-project.org') do
      :inet_res.gethostbyname(hostname)
    end
  end

  defmodule NTP do
    use GenServer

    def start_link do
      GenServer.start_link(__MODULE__, [], name: __MODULE__)
    end
  end

  def start_link(_, opts) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    Logger.debug "Starting up network!"
    import Ecto.Query
    interfaces = ConfigStorage.all(from i in NetworkInterface)
    children = Enum.map(interfaces, fn(interface) ->
      start_iface(interface)
      worker(NetworkWatcher, [interface.name])
    end) ++ [worker(NTP, [])]
    {:ok, sup} = supervise(children, [strategy: :one_for_one])
    wait_for_network()
    {:ok, sup}
  end

  defp start_iface(%{type: "wired"} = iface) do
    Nerves.Network.setup iface.name, [ipv4_address_method: :"#{iface.ipv4_method}"]
  end

  defp start_iface(iface) do
    Nerves.Network.setup iface.name, [ipv4_address_method: :"#{iface.ipv4_method}", ssid: iface.ssid, psk: iface.psk, key_mgmt: :"#{iface.security}"]
  end

  defp wait_for_network do
    unless :os.system_time() > 1507149578330507924 do
      Process.sleep(10)
      wait_for_network()
    end
    :ok
  end
end
