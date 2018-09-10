defmodule Farmbot.Target.DiskUsageWorker do
  use GenServer
  @data_path Application.get_env(:farmbot, :data_path)
  @data_path || Mix.raise("No data path.")

  def start_link(_, opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    send(self(), :report_disk_usage)
    {:ok, %{}}
  end

  def handle_info(:report_disk_usage, state) do
    usage = collect_report()

    if GenServer.whereis(Farmbot.BotState) do
      Farmbot.BotState.report_disk_usage(usage)
      Process.send_after(self(), :report_disk_usage, 60_000)
    else
      Process.send_after(self(), :report_disk_usage, 5000)
    end
    {:noreply, state}
  end

  def collect_report do
    {usage_str, 0} = Nerves.Runtime.cmd("df", ["-h", @data_path], :return)
    {usage, "%"} = usage_str
      |> String.split("\n")
      |> Enum.at(1)
      |> String.split(" ")
      |> Enum.at(-2)
      |> Integer.parse()
    usage
  end
end
