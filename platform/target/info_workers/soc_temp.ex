defmodule FarmbotOS.Platform.Target.InfoWorker.SocTemp do
  @moduledoc """
  Worker responsible for reporting current system
  on a chip package temperature.

  Specific to raspberry pi using the vcgencmd command
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
    {temp_str, 0} = Nerves.Runtime.cmd("vcgencmd", ["measure_temp"], :return)

    temp =
      temp_str
      |> String.trim()
      |> String.split("=")
      |> List.last()
      |> Integer.parse()
      |> elem(0)

    if GenServer.whereis(BotState) do
      :ok = BotState.report_soc_temp(temp)
      {:noreply, state, @default_timeout_ms}
    else
      {:noreply, state, @error_timeout_ms}
    end
  end
end
