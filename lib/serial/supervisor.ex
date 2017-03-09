defmodule Farmbot.Serial.Supervisor do
  @moduledoc false
  use Supervisor
  require Logger
  alias Nerves.UART
  alias Farmbot.Serial.Handler

  @baud 115_200
  @default_tracker :default_tracker

  defmodule DefaultTracker do
    @moduledoc false

    @doc false
    def start_link(name) do
      Agent.start_link(fn() -> nil end, name: name)
    end
  end

  def init([]) do
    children = [
      worker(UART, [[name: UART]], restart: :permanent, name: UART),
      worker(DefaultTracker, [@default_tracker], restart: :permanent),
      worker(Task, [__MODULE__, :open_ttys, [__MODULE__, UART]], restart: :transient)
      # worker(Farmbot.Serial.Monitor, [UART], restart: :permanent)
    ]
    supervise(children, strategy: :one_for_all)
  end

  @doc """
    Start the serial supervisor
  """
  def start_link do
    Logger.info ">> is starting serial services"
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
    Stop the Serial Supervisor
  """
  def stop do
    Supervisor.stop(__MODULE__)
  end

  @spec open_ttys(atom | pid, atom | pid) :: :ok | no_return
  def open_ttys(supervisor, nerves_uart) do
    UART.enumerate()
    |> Map.drop(["ttyS0","ttyAMA0"])
    |> Map.keys
    |> try_open({supervisor, nerves_uart})
  end

  @spec try_open([binary], {atom | pid, atom | pid}) :: :ok | no_return
  defp try_open([], _), do: :ok
  defp try_open([tty | rest], {sup, nerves}) do
    nerves
    |> UART.open(tty, speed: @baud, active: false)
    |> bleep(tty, {sup, nerves})

    try_open(rest, {sup, nerves})
  end

  @spec bleep(any, binary, {atom | pid, atom | pid})
    :: {:ok, pid} | false | no_return
  defp bleep(:ok, tty, {sup, nerves}) do
    worker_spec = worker(Handler, [nerves, tty], [restart: :permanent])
    UART.close(nerves)
    {:ok, _pid} = Supervisor.start_child(sup, worker_spec)
  end

  defp bleep(_resp, _tty, _sup_nerves), do: false
end
