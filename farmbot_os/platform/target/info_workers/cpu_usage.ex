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
    :erlang.system_flag(:scheduler_wall_time, true)
    stat0 = :lists.sort(:erlang.statistics(:scheduler_wall_time))
    Process.sleep(1000)
    stat1 = :lists.sort(:erlang.statistics(:scheduler_wall_time))
    {active, total} = Enum.zip(stat0, stat1) |> List.foldl({0, 0}, fn {{_, a0, t0}, {_, a1, t1}}, {ai, ti} -> {ai + (a1 - a0), ai + (t1 - t0)} end)
    ((active / total) * (:erlang.system_info(:schedulers) + :erlang.system_info(:dirty_cpu_schedulers))) / :erlang.system_info(:logical_processors_available)
  end
end
