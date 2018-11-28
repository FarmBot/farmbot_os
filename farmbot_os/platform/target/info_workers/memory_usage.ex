defmodule Farmbot.Target.InfoWorker.MemoryUsage do
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
      Farmbot.BotState.report_memory_usage(usage)
      {:noreply, state, @default_timeout_ms}
    else
      {:noreply, state, @error_timeout_ms}
    end
  end

  def collect_report do
    round(:erlang.memory(:total) * 1.0e-6)
  end
end
