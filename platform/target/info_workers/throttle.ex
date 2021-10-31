defmodule FarmbotOS.Platform.Target.InfoWorker.Throttle do
  @moduledoc """
  RPI specific worker responsible for checking the `throttled` flag
  as reported by vcgencmd
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
    {throttled_str, 0} =
      Nerves.Runtime.cmd("vcgencmd", ["get_throttled"], :return)

    throttled =
      throttled_str
      |> String.trim()
      |> String.split("=")
      |> List.last()

    if GenServer.whereis(BotState) do
      :ok = BotState.report_throttled(throttled)
      {:noreply, state, @default_timeout_ms}
    else
      {:noreply, state, @error_timeout_ms}
    end
  end
end
