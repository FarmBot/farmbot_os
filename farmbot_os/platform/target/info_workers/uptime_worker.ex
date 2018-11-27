defmodule Farmbot.Target.UptimeWorker do
  @moduledoc false

  use GenServer
  @default_timeout_ms 60_000
  @error_timeout_ms 5_000

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init([]) do
    {:ok, nil, 0}
  end

  def handle_info(:timeout, state) do
    usage = collect_report()

    if GenServer.whereis(Farmbot.BotState) do
      Farmbot.BotState.report_uptime(usage)
      {:noreply, state, @default_timeout_ms}
    else
      {:noreply, state, @error_timeout_ms}
    end
  end

  def collect_report do
    {wall_clock_ms, _last_call} = :erlang.statistics(:wall_clock)
    round(wall_clock_ms * 0.001)
  end
end
