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
    {:ok, %{interface: interface, ip_address: nil, connected: false, not_found_timer: nil, ntp_timer: nil}}
  end

  def handle_call(:ip, _, state) do
    {:reply, state.ip_address, state}
  end

  def handle_info({:system_registry, :global, registry}, state) do
    ip = get_in(registry, [:state, :network_interface, state.interface, :ipv4_address])
    ntp_timer = if ip != state.ip_address do
      # Logger.warn(3, "ip address changed on interface: #{state.interface}: #{ip}")
      maybe_cancel_and_reset_ntp_timer(state.ntp_timer)
    else
      nil
    end


    connected = match?({:ok, {:hostent, 'nerves-project.org', [], :inet, 4, _}}, test_dns())
    if connected do
      not_found_timer = cancel_not_found_timer(state.not_found_timer)
      {:noreply, %{state | ip_address: ip, connected: true, not_found_timer: not_found_timer, ntp_timer: ntp_timer}}
    else
      {:noreply, %{state | connected: false, ntp_timer: ntp_timer, ip_address: ip}}
    end
  end

  def handle_info({Nerves.WpaSupplicant, {:INFO, "WPA: 4-Way Handshake failed - pre-shared key may be incorrect"}, _}, state) do
    Logger.error 1, "Incorrect PSK."
    Farmbot.System.factory_reset("WIFI Authentication failed. (incorrect psk)")
    {:stop, :normal, state}
  end

  def handle_info({Nerves.WpaSupplicant, :"CTRL-EVENT-NETWORK-NOT-FOUND", _}, %{not_found_timer: nil} = state) do
    first_boot = ConfigStorage.get_config_value(:bool, "settings", "first_boot")
    # stored in minutes
    delay_timer = (ConfigStorage.get_config_value(:float, "settings", "network_not_found_timer") || 1) *  60_000
    cond do
      first_boot ->
        Logger.error 1, "Network not found"
        Farmbot.System.factory_reset("WIFI Authentication failed. (network not found)")
        {:stop, :normal, state}
      delay_timer > 0 ->
        Logger.warn 1, "Network not found. Starting timer."
        timer = Process.send_after(self(), :network_not_found_timer, round(delay_timer))
        {:noreply, %{state | not_found_timer: timer, connected: false}}
      is_nil(delay_timer) ->
        Logger.error 1, "Network not found"
        Farmbot.System.factory_reset("WIFI Authentication failed. (network not found)")
        {:stop, :normal, state}
    end
  end

  def handle_info({Nerves.WpaSupplicant, :"CTRL-EVENT-NETWORK-NOT-FOUND"}, state) do
    {:noreply, %{state | connected: false}}
  end

  def handle_info(:network_not_found_timer, state) do
    if state.connected do
      Logger.warn 1, "Not resetting because network is connected."
      {:noreply, %{state | not_found_timer: nil}}
    else
      Logger.error 1, "Network not found"
      Farmbot.System.factory_reset("WIFI Authentication failed. (network not found after timer)")
      {:stop, :normal, state}
    end
  end

  def handle_info(:ntp_timer, state) do
    new_timer = maybe_cancel_and_reset_ntp_timer(state.ntp_timer)
    {:noreply, %{state | ntp_timer: new_timer}}
  end

  def handle_info(_event, state) do
    # Logger.warn 3, "unhandled network event: #{inspect event}"
    {:noreply, state}
  end

  defp cancel_not_found_timer(timer) do
    # If there was a timer, cancel it.
    if timer do
      Logger.warn 3, "Cancelling Network timer"
      Process.cancel_timer(timer)
    end
    nil
  end

  defp maybe_cancel_and_reset_ntp_timer(timer) do
    if timer do
      Process.cancel_timer(timer)
    end
    # introduce a bit of randomness to avoid dosing ntp servers.
    # I don't think this would ever happen but the default ntpd implementation
    # does this..
    rand = :rand.uniform(5000)

    case Ntp.set_time() do

      # If we Successfully set time, sync again in around 1024 seconds
      :ok -> Process.send_after(self(), :ntp_timer, 1024000 + rand)
      # If time failed, try again in about 5 minutes.
      _ ->
        if Farmbot.System.ConfigStorage.get_config_value(:bool, "settings", "first_boot") do
          Process.send_after(self(), :ntp_timer, 10_000 + rand)
        else

          Process.send_after(self(), :ntp_timer, 300000 + rand)
        end
    end
  end
end
