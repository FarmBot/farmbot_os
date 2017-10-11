defmodule Farmbot.Target.Network do
  @moduledoc "Bring up network."

  @behaviour Farmbot.System.Init
  alias Farmbot.System.ConfigStorage
  alias ConfigStorage.NetworkInterface
  use Supervisor
  require Logger

  def test_dns(hostname \\ 'nerves-project.org') do
    :inet_res.gethostbyname(hostname)
  end

  defmodule NetworkWatcher do
    use GenServer
    require Logger

    def start_link(name) do
      GenServer.start_link(__MODULE__, name, name: :"network_interface_#{name}")
    end

    def init(name) do
      Logger.debug("Starting NetworkWatcher - #{name}")
      SystemRegistry.register()
      {:ok, %{name: name, connected: false}}
    end

    def handle_info({:system_registry, :global, registry}, state) do
      _status = get_in(registry, [:state, :network_interface, state.name])

      connected =
        match?(
          {:ok, {:hostent, 'nerves-project.org', [], :inet, 4, _}},
          Farmbot.Target.Network.test_dns()
        )

      if connected do
        Logger.debug("Connected!")
      end

      {:noreply, %{state | connected: connected}}
    end
  end

  defmodule NTP do
    use GenServer
    require Logger

    def start_link do
      GenServer.start_link(__MODULE__, [], name: __MODULE__)
    end

    def init([]) do
      Process.send_after(self(), :time, 1000)
      {:ok, %{dns: false}}
    end

    def handle_info(:time, state) do
      dns =
        match?(
          {:ok, {:hostent, '0.pool.ntp.org', [], :inet, 4, _}},
          Farmbot.Target.Network.test_dns('0.pool.ntp.org')
        )

      if dns do
        Logger.debug("Have dns. Setting time.")
        :os.cmd('ntpd -p 0.pool.ntp.org -p 1.pool.ntp.org')
      else
        Logger.warn("No dns. Trying again.")
        Process.send_after(self(), :time, 1000)
      end

      {:ok, %{state | dns: dns}}
    end
  end

  def start_link(_, opts) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    Logger.debug("Starting up network!")
    import Ecto.Query
    interfaces = ConfigStorage.all(from(i in NetworkInterface))

    children =
      Enum.map(interfaces, fn interface ->
        start_iface(interface)
        worker(NetworkWatcher, [interface.name])
      end) ++ [worker(NTP, [])]

    {:ok, sup} = supervise(children, strategy: :one_for_one)
    wait_for_network()
    {:ok, sup}
  end

  defp start_iface(%{type: "wired"} = iface) do
    Nerves.Network.setup(iface.name, [])
  end

  defp start_iface(iface) do
    Nerves.Network.setup(
      iface.name,
      ssid: iface.ssid,
      psk: iface.psk,
      key_mgmt: :"#{iface.security}"
    )
  end

  defp wait_for_network do
    time = :os.system_time()

    unless time > 1_507_149_578_330_507_924 do
      Process.sleep(10)
      if rem(time, 10) == 0, do: Logger.debug("Waiting for time: #{time}")
      wait_for_network()
    end

    :ok
  end
end
