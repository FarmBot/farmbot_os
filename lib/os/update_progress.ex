defmodule FarmbotOS.UpdateProgress do
  use GenServer
  require FarmbotOS.Logger

  alias FarmbotOS.{
    BotState.JobProgress.Percent,
    BotState
  }

  # Arbitrary
  @timer_creep_ms 1792
  @increment 1.04

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [])
  end

  def init(_args) do
    {:ok, tick(self(), 0)}
  end

  def handle_info(:timeout, state) do
    {:noreply, tick(self(), state[:percent])}
  end

  def set(pid, percent) do
    GenServer.call(pid, {:set, percent})
  end

  def handle_call({:set, percent}, _from, _state) do
    {:reply, :ok, %{percent: percent}}
  end

  def tick(pid, last_percent) do
    inc =
      case round(last_percent / 10) do
        9 -> @increment / 32
        8 -> @increment / 16
        7 -> @increment / 8
        6 -> @increment / 4
        _ -> @increment
      end

    next_percent = last_percent + inc

    if next_percent < 99 do
      Process.send_after(pid, :timeout, @timer_creep_ms)
      set_progress(%Percent{percent: Float.round(next_percent, 2)})
    else
      set_progress(%Percent{percent: 100, status: "Complete"})
    end

    %{percent: next_percent}
  end

  def set_progress(percent) do
    if Process.whereis(BotState) do
      percent2 = Map.put(percent, :type, "OTA")
      BotState.set_job_progress("FBOS_OTA", percent2)
    end
  end
end
