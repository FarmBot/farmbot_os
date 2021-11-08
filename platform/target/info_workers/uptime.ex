defmodule FarmbotOS.Platform.Target.InfoWorker.Uptime do
  @moduledoc """
  Worker process responsible for reporting uptime to the
  bot_state server
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
      BotState.report_uptime(usage)
      {:noreply, state, @default_timeout_ms}
    else
      {:noreply, state, @error_timeout_ms}
    end
  end

  @doc "returns wall_clock time in seconds"
  def collect_report do
    {wall_clock_ms, _last_call} = :erlang.statistics(:wall_clock)
    round(wall_clock_ms * 0.001)
  end
end
