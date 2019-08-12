defmodule FarmbotOS.Platform.Target.InfoWorker.WifiLevel do
  use GenServer
  require FarmbotCore.Logger
  alias FarmbotCore.BotState

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(_args) do
    send(self(), :load_network_config)
    {:ok, %{ssid: nil}}
  end

  def handle_info(:load_network_config, state) do
    if FarmbotCore.Config.get_network_config("eth0") do
      FarmbotCore.Logger.warn(3, """
      FarmBot configured to use ethernet 
      Disabling WiFi status reporting
      """)

      {:noreply, state}
    else
      case FarmbotCore.Config.get_network_config("wlan0") do
        %{ssid: ssid} ->
          VintageNet.subscribe(["interface", "wlan0"])
          {:noreply, %{state | ssid: ssid}}

        nil ->
          Process.send_after(self(), :load_network_config, 10_000)
          {:noreply, %{state | ssid: nil}}
      end
    end
  end

  def handle_info(
        {VintageNet, ["interface", "wlan0", "wifi", "access_points"], _, new, _meta},
        %{ssid: ssid} = state
      )
      when is_binary(ssid) do
    ap = find_ap(new, ssid)

    if ap do
      :ok = BotState.report_wifi_level(ap.signal_dbm)
      :ok = BotState.report_wifi_level_percent(ap.signal_percent)
    end

    {:noreply, state}
  end

  def handle_info({VintageNet, _property, _old, _new, _meta}, state) do
    {:noreply, state}
  end

  defp find_ap(new, ssid) do
    Enum.find_value(new, fn
      %{ssid: ^ssid} = ap -> ap
      _ -> false
    end)
  end
end
