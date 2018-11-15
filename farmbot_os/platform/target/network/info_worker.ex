defmodule Farmbot.Target.Network.InfoWorker do
  @moduledoc false
  use GenServer
  @default_timeout_ms 60_000

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init([config]) do
    {:ok, config, 0}
  end

  def handle_info(:timeout, %{type: "wireless"} = config) do
    if level = Farmbot.Target.Network.get_level(config.name, config.ssid) do
      report_wifi_level(level)
    end

    {:noreply, config, @default_timeout_ms}
  end

  def handle_info(:timeout, config) do
    {:noreply, config, :hibernate}
  end

  def report_wifi_level(level) do
    if GenServer.whereis(Farmbot.BotState) do
      Farmbot.BotState.report_wifi_level(level)
    end
  end
end
