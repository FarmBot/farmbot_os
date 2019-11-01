defmodule FarmbotCore.BotState.SchedulerUsageReporter do
  alias FarmbotCore.BotState
  require FarmbotTelemetry
  use GenServer
  @default_timeout_ms 5000
  @schedulers [:scheduler, :dirty_cpu_scheduler]

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(_args) do
    _ = :msacc.stop()
    _ = :msacc.reset()
    _ = :msacc.start()
    {:ok, %{}, @default_timeout_ms}
  end

  def handle_info(:timeout, state) do
    scheduler_info =
      for %{
            type: type,
            counters: %{
              aux: aux,
              check_io: check_io,
              emulator: emulator,
              gc: gc,
              other: other,
              port: port,
              sleep: sleep
            }
          }
          when type in @schedulers <- :msacc.stats(:type, :msacc.stats()) do
        denominator = aux + check_io + emulator + gc + other + port + sleep
        numerator = denominator - sleep
        {"#{type}", numerator / denominator}
      end

    sched_effort =
      Enum.map_reduce(scheduler_info, 0, fn sched_info, acc ->
        work = elem(sched_info, 1)
        {work, work + acc}
      end)

    _ = BotState.report_scheduler_usage(round(elem(sched_effort, 1) / length(@schedulers) * 100))
    _ = :msacc.reset()
    {:noreply, state, @default_timeout_ms}
  end
end
