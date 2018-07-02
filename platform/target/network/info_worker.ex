defmodule Farmbot.Target.Network.InfoWorker do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init([config]) do
    send(self(), :report_info)
    {:ok, config}
  end

  def handle_info(:report_info, %{type: "wireless"} = config) do
    if level = Farmbot.Target.Network.get_level(config.name, config.ssid) do
      report_wifi_level(level)
    end
    Process.send_after(self(), :report_info, 60_000)
    {:noreply, config}
  end

  def handle_info(:report_info, config) do
    Process.send_after(self(), :report_info, 60_000)
    {:noreply, config}
  end

  def report_wifi_level(level) do
    if GenServer.whereis(Farmbot.BotState) do
      Farmbot.BotState.report_wifi_level(level)
    end
  end
end
