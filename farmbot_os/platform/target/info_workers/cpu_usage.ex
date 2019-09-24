defmodule FarmbotOS.Platform.Target.InfoWorker.CpuUsage do
  @moduledoc false

  use GenServer
  @default_timeout_ms 60_000
  @error_timeout_ms 5_000
  alias FarmbotCore.BotState

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init([]) do
    {:ok, nil, 0}
  end

  def handle_info(:timeout, state) do
    usage = collect_report()

    if GenServer.whereis(BotState) do
      BotState.report_cpu_usage(usage)
      {:noreply, state, @default_timeout_ms}
    else
      {:noreply, state, @error_timeout_ms}
    end
  end

  def collect_report do
    round(:erlang.statistics(:scheduler_wall_time))
  end
end
