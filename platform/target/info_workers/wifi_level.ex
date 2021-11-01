defmodule FarmbotOS.Platform.Target.InfoWorker.WifiLevel do
  @moduledoc """
  Worker process responsible for reporting current wifi
  power levels to the bot_state server
  """

  @report_interval 7_000

  use GenServer
  alias FarmbotOS.BotState

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl GenServer
  def init(_args) do
    send(self(), :load_network_config)
    {:ok, %{ssid: nil}}
  end

  @impl GenServer
  def handle_info(:timeout, state) do
    maybe_report_wifi(VintageNet.ioctl("wlan0", :signal_poll))
    {:noreply, state, @report_interval}
  end

  def handle_info(:load_network_config, state) do
    if FarmbotOS.Config.get_network_config("eth0") do
      VintageNet.subscribe(["interface", "eth0"])

      {:noreply, state}
    else
      case FarmbotOS.Config.get_network_config("wlan0") do
        %{ssid: ssid} ->
          VintageNet.subscribe(["interface", "wlan0"])
          {:noreply, %{state | ssid: ssid}, @report_interval}

        nil ->
          Process.send_after(self(), :load_network_config, 10_000)
          {:noreply, %{state | ssid: nil}}
      end
    end
  end

  def handle_info(
        {VintageNet, ["interface", _, "addresses"], _old,
         [%{address: address} | _], _meta},
        state
      ) do
    FarmbotOS.BotState.set_private_ip(to_string(:inet.ntoa(address)))
    {:noreply, state, @report_interval}
  end

  def handle_info({VintageNet, _property, _old, _new, _meta}, state) do
    {:noreply, state, @report_interval}
  end

  def maybe_report_wifi({:ok, signal_info} = result) do
    :ok = BotState.report_wifi_level(signal_info.signal_dbm)
    :ok = BotState.report_wifi_level_percent(signal_info.signal_percent)
    result
  end

  def maybe_report_wifi(other), do: other
end
