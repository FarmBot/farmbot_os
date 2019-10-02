defmodule FarmbotCore.BotState.SchedulerUsageReporter do
  alias FarmbotCore.BotState
  use GenServer
  @default_timeout_ms 5000

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(_args) do
    _ = :msacc.start()
    {:ok, %{}, @default_timeout_ms}
  end

  def handle_info(:timeout, state) do
    scheduler_info = for %{
      type: type,
      id: id,
      counters: %{
        aux: aux,
        check_io: check_io,
        emulator: emulator,
        gc: gc,
        other: other,
        port: port,
        sleep: sleep
      }
    } when type in [:scheduler, :dirty_cpu_scheduler] <- :msacc.stats() do
      denominator = aux + check_io + emulator + gc + other + port + sleep
      numerator = denominator - sleep
      {"#{type}_#{id}", numerator / denominator}
    end

    average = calculate_average(scheduler_info, Enum.count(scheduler_info))
    _ = BotState.report_scheduler_usage(average)
    {:noreply, state, @default_timeout_ms}
  end

  defp calculate_average(usage, count, acc \\ 0)
  defp calculate_average([{_, usage} | rest], count, acc), 
    do: calculate_average(rest, count, acc + usage)
  defp calculate_average([], count, acc), 
    do: round((acc / count) * 100)
end