defmodule FarmbotOS.Platform.Target.InfoWorker.DiskUsage do
  @moduledoc """
  Worker responsible for reporting disk usage to the
  bot_state server
  """

  use GenServer
  @data_path FarmbotOS.FileSystem.data_path()
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
      BotState.report_disk_usage(usage)
      {:noreply, state, @default_timeout_ms}
    else
      {:noreply, state, @error_timeout_ms}
    end
  end

  @doc "Returns current disk usage as a percent"
  def collect_report do
    {usage_str, 0} = Nerves.Runtime.cmd("df", ["-h", @data_path], :return)

    {usage, "%"} =
      usage_str
      |> String.split("\n")
      |> Enum.at(1)
      |> String.split(" ")
      |> Enum.at(-2)
      |> Integer.parse()

    usage
  end
end
