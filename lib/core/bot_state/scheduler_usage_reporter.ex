defmodule FarmbotOS.BotState.SchedulerUsageReporter do
  alias FarmbotOS.BotState
  require Logger

  use GenServer

  @collect_duration 2_000
  @report_interval 7_000

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(_args) do
    _ = :msacc.stop()
    {:ok, load_ave} = File.open(~c"/proc/loadavg", [:read])
    start_abs = System.monotonic_time(:millisecond)

    _ =
      Process.send_after(self(), :report, start_abs + @report_interval, [
        {:abs, true}
      ])

    _ = Process.send_after(self(), :collect, start_abs, [{:abs, true}])

    _ =
      Process.send_after(self(), :collect_stop, start_abs + @collect_duration, [
        {:abs, true}
      ])

    _ = :erlang.process_flag(:priority, :high)
    {:ok, %{load_ave_dev: load_ave, next_report_abs: start_abs}}
  end

  def handle_info(:collect, state) do
    _ = :msacc.reset()
    _ = :msacc.start()
    {:noreply, state}
  end

  def handle_info(:collect_stop, state) do
    _ = :msacc.stop()
    {:noreply, state}
  end

  def handle_info(:report, state) do
    msacc_counters = :erlang.statistics(:microstate_accounting)

    average_thread_realtime =
      :msacc.stats(:system_realtime, msacc_counters) / length(msacc_counters)

    scheduler_info =
      for %{
            counters: %{
              aux: aux,
              check_io: check_io,
              emulator: emulator,
              gc: gc,
              other: other,
              port: port,
              sleep: _sleep
            },
            id: _id,
            type: type
          }
          when type in [:scheduler] <- msacc_counters do
        aux + check_io + emulator + gc + other + port
      end

    sched_effort =
      Enum.map_reduce(scheduler_info, 0, fn runtime, acc ->
        {runtime, acc + runtime}
      end)

    usage =
      elem(sched_effort, 1) / (average_thread_realtime * length(scheduler_info)) *
        100

    _ = BotState.report_scheduler_usage(round(usage))

    if usage >= 99.9 do
      :file.position(state.load_ave_dev, 0)
      load_average = String.slice(IO.read(state.load_ave_dev, :line), 0..-2)

      Logger.debug(
        "sched usage #{round(usage)}% : run queue lengths #{inspect(:erlang.statistics(:run_queue_lengths))} : load average #{load_average}"
      )
    end

    next_report_abs = state.next_report_abs + @report_interval

    next_collect_abs =
      state.next_report_abs +
        100 *
          :rand.uniform(round((@report_interval - @collect_duration) / 100) - 1)

    _ = Process.send_after(self(), :report, next_report_abs, [{:abs, true}])
    _ = Process.send_after(self(), :collect, next_collect_abs, [{:abs, true}])

    _ =
      Process.send_after(
        self(),
        :collect_stop,
        next_collect_abs + @collect_duration,
        [{:abs, true}]
      )

    {:noreply, %{state | next_report_abs: next_report_abs}}
  end
end
