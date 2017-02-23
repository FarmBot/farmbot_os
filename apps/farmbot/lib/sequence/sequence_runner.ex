defmodule SequenceRunner do
  @moduledoc """
    Runs a sequence
  """

  use Farmbot.Sync.Database
  require Logger
  use GenServer
  alias Farmbot.CeleryScript.Ast

  @type state :: Ast.t

  @doc """
    Starts a sequence.
  """
  def start_link(sequence), do: GenServer.start_link(__MODULE__, sequence)

  @spec init(Sequence.t) :: {:ok, state}
  def init(sequence) do
    sequence = Ast.parse(sequence)
    spawn __MODULE__, :work, [sequence, self()]
    {:ok, sequence}
  end

  @spec handle_cast({:work, Ast.t}, state) :: {:noreply, state}
  def handle_cast({:work, %Ast{} = seq}, _) do
    spawn __MODULE__, :work, [seq, self()]
    {:noreply, seq}
  end

  @spec work(Ast.t, pid) :: no_return
  def work(%Ast{body: []} = _sequence, pid) do
    GenServer.stop(pid, :normal)
  end

  def work(%Ast{body: [next | rest]} = sequence, pid) do
    Farmbot.CeleryScript.Command.do_command(next)
    GenServer.cast(pid, {:work, %{sequence | body: rest}})
  end
end
