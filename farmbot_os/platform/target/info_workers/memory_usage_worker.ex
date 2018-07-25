defmodule Farmbot.Target.MemoryUsageWorker do
  use GenServer
  def start_link(_, opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    send(self(), :report_memory_usage)
    {:ok, %{}}
  end

  def handle_info(:report_memory_usage, state) do
    usage = collect_report()

    if GenServer.whereis(Farmbot.BotState) do
      Farmbot.BotState.report_memory_usage(usage)
      Process.send_after(self(), :report_memory_usage, 60_000)
    else
      Process.send_after(self(), :report_memory_usage, 5000)
    end
    {:noreply, state}
  end

  def collect_report do
    round(:erlang.memory(:total) * 1.0e-6)
  end
end
