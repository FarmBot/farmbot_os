defmodule Farmbot.Target.DiskUsageWorker do
  @moduledoc false

  use GenServer
  @data_path Farmbot.OS.FileSystem.data_path()
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
      Farmbot.BotState.report_disk_usage(usage)
      {:noreply, state, @default_timeout_ms}
    else
      {:noreply, state, @error_timeout_ms}
    end
  end

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
