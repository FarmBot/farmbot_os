defmodule Farmbot.Target.Network.Manager do
  use GenServer
  use Farmbot.Logger
  alias Nerves.Network
  alias Farmbot.Target.Network.Ntp
  import Farmbot.Target.Network, only: [test_dns: 0]

  def start_link(interface, opts) do
    GenServer.start_link(__MODULE__, {interface, opts}, [name: :"#{__MODULE__}-#{interface}"])
  end

  def init({interface, opts} = args) do
    Logger.busy(3, "Waiting for interface up.")
    unless interface in Nerves.NetworkInterface.interfaces() do
      Process.sleep(1000)
      init(args)
    end
    SystemRegistry.register()
    {:ok, _} = Registry.register(Nerves.NetworkInterface, interface, [])
    {:ok, _} = Registry.register(Nerves.Udhcpc, interface, [])
    {:ok, _} = Registry.register(Nerves.WpaSupplicant, interface, [])
    Network.setup(interface, opts)
    {:ok, %{interface: interface, ip_address: nil, connected: false}}
  end

  def handle_info({:system_registry, :global, registry}, state) do
    ip = get_in(registry, [:state, :network_interface, state.interface, :ipv4_address])

    if ip != state.ip_address do
      Logger.warn(3, "ip address changed on interface: #{state.interface}: #{ip}")
      :ok = Ntp.set_time()
    end

    connected = match?({:ok, {:hostent, 'nerves-project.org', [], :inet, 4, _}}, test_dns())
    {:noreply, %{state | ip_address: ip, connected: connected || false}}
  end

  def handle_info({Nerves.WpaSupplicant, {:INFO, "WPA: 4-Way Handshake failed - pre-shared key may be incorrect"}, _}, state) do
    Logger.error 1, "Incorrect PSK."
    Farmbot.System.factory_reset("WIFI Authentication failed. (incorrect psk)")
    {:stop, :normal, state}
  end

  def handle_info(_event, state) do
    # Logger.warn 3, "unhandled network event: #{inspect event}"
    {:noreply, state}
  end
end
