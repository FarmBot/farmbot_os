defmodule Farmbot.Target.SocTempWorker do
  use GenServer
  def start_link(_, opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    send(self(), :report_temp)
    {:ok, %{}}
  end

  def handle_info(:report_temp, state) do
    temp = collect_report()
    if GenServer.whereis(Farmbot.BotState) do
      Farmbot.BotState.report_soc_temp(temp)
      Process.send_after(self(), :report_temp, 60_000)
    else
      Process.send_after(self(), :report_temp, 5000)
    end
    {:noreply, state}
  end

  def collect_report do
    {temp_str, 0} = Nerves.Runtime.cmd("vcgencmd", ["measure_temp"], :return)
    temp_str
      |> String.trim()
      |> String.split("=")
      |> List.last()
      |> Float.parse
      |> elem(0)
  end
end
