defmodule Farmbot.Target.SocTempWorker do
  use GenServer
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    send(self(), :report_temp)
    {:ok, %{}}
  end

  def handle_info(:report_temp, state) do
    {temp_str, 0} = Nerves.Runtime.cmd("vcgencmd", ["measure_temp"], :return)
    temp = temp_str
      |> String.trim()
      |> String.split("=")
      |> List.last()
      |> Float.parse
      |> elem(0)
    if GenServer.whereis(Farmbot.BotState) do
      Farmbot.BotState.report_soc_temp(temp)
      Process.send_after(self(), :report_temp, 60_000)
    else
      Process.send_after(self(), :report_temp, 5000)
    end
    {:noreply, state}
  end
end
