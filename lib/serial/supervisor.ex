defmodule Farmbot.Serial.Supervisor do
  @moduledoc false
  use Supervisor
  require Logger
  alias Nerves.UART
  alias Farmbot.Serial.Handler

  @baud 115_200

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

  def init([]) do
    children = [
      worker(Task, [__MODULE__, :open_ttys, [__MODULE__]], restart: :transient)
    ]
    supervise(children, strategy: :one_for_all)
  end

  @spec open_ttys(atom | pid, [binary]) :: :ok | no_return
  def open_ttys(supervisor, ttys \\ nil) do
    blah = ttys || UART.enumerate() |> Map.drop(["ttyS0","ttyAMA0"]) |> Map.keys
    blah |> try_open(supervisor)
  end

  @spec try_open([binary], atom | pid) :: :ok | no_return
  defp try_open([], _), do: :ok
  defp try_open([tty | rest], sup) do
    {:ok, nerves} = UART.start_link()
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

  defp bleep(_resp, _tty, {_, nerves}) do
    GenServer.stop(nerves, :normal)
    false
  end
end
