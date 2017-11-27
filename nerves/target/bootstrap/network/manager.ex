defmodule Farmbot.Target.Network.Manager do
  use GenServer
  use Farmbot.Logger
  alias Farmbot.System.ConfigStorage
  alias Nerves.Network
  alias Farmbot.Target.Network.Ntp
  import Farmbot.Target.Network, only: [test_dns: 0]

  def get_ip_addr(interface) do
    GenServer.call(:"#{__MODULE__}-#{interface}", :ip)
  end

  def start_link(interface, opts) do
    GenServer.start_link(__MODULE__, {interface, opts}, [name: :"#{__MODULE__}-#{interface}"])
  end

  def init({interface, opts} = args) do
    Elixir.Logger.remove_backend Elixir.Logger.Backends.Console
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
    {:ok, %{interface: interface, ip_address: nil, connected: false, not_found_timer: nil}}
  end

  def handle_call(:ip, _, state) do
    {:reply, state.ip_address, state}
  end

  def handle_info({:system_registry, :global, registry}, state) do
    ip = get_in(registry, [:state, :network_interface, state.interface, :ipv4_address])

    if ip != state.ip_address do
      Logger.warn(3, "ip address changed on interface: #{state.interface}: #{ip}")
      :ok = Ntp.set_time()
    end

    connected = match?({:ok, {:hostent, 'nerves-project.org', [], :inet, 4, _}}, test_dns())
    if connected do
      if state.not_found_timer do
        Process.cancel_timer(state.not_found_timer)
      end
      {:noreply, %{state | ip_address: ip, connected: true, not_found_timer: nil}}
    else
      {:noreply, %{state | connected: false}}
    end
  end

  def handle_info({Nerves.WpaSupplicant, {:INFO, "WPA: 4-Way Handshake failed - pre-shared key may be incorrect"}, _}, state) do
    Logger.error 1, "Incorrect PSK."
    Farmbot.System.factory_reset("WIFI Authentication failed. (incorrect psk)")
    {:stop, :normal, state}
  end

  def handle_info({Nerves.WpaSupplicant, :"CTRL-EVENT-NETWORK-NOT-FOUND", _}, %{not_found_timer: nil} = state) do
    first_boot = ConfigStorage.get_config_value(:bool, "settings", "first_boot")
    delay_timer = ConfigStorage.get_config_value(:float, "settings", "network_not_found_timer")
    cond do
      first_boot ->
        Logger.error 1, "Network not found"
        Farmbot.System.factory_reset("WIFI Authentication failed. (network not found)")
        {:stop, :normal, state}
      delay_timer > 0 ->
        Logger.warn 1, "Network not found. Starting timer."
        timer = Process.send_after(self(), :network_not_found_timer, round(delay_timer))
        {:noreply, %{state | not_found_timer: timer}}
      delay_timer == -1 -> {:noreply, state}
      is_nil(delay_timer) ->
        Logger.error 1, "Network not found"
        Farmbot.System.factory_reset("WIFI Authentication failed. (network not found)")
        {:stop, :normal, state}
    end
  end

  def handle_info({Nerves.WpaSupplicant, :"CTRL-EVENT-NETWORK-NOT-FOUND"}, state) do
    {:noreply, state}
  end

  def handle_info(:network_not_found_timer, state) do
    if state.connected do
      {:noreply, %{state | not_found_timer: nil}}
    else
      Logger.error 1, "Network not found"
      Farmbot.System.factory_reset("WIFI Authentication failed. (network not found after timer)")
      {:stop, :normal, state}
    end
  end

  def handle_info(_event, state) do
    # Logger.warn 3, "unhandled network event: #{inspect event}"
    {:noreply, state}
  end
end
