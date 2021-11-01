defmodule FarmbotOS.Platform.Target.InfoWorker.MemoryUsage do
  @moduledoc """
  Worker responsible for reporting memory usage
  to the bot_state server
  """

  use GenServer
  @default_timeout_ms 60_000
  @error_timeout_ms 5_000
  alias FarmbotOS.BotState

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl GenServer
  def init([]) do
    {:ok, nil, 0}
  end

  @impl GenServer
  def handle_info(:timeout, state) do
    usage = collect_report()

    if GenServer.whereis(BotState) do
      BotState.report_memory_usage(usage)
      {:noreply, state, @default_timeout_ms}
    else
      {:noreply, state, @error_timeout_ms}
    end
  end

  @doc "returns current VM memory usage expressed as a percent"
  def collect_report do
    round(:erlang.memory(:total) * 1.0e-6)
  end
end
