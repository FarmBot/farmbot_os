defmodule SequenceRunner do
  @moduledoc """
    Runs a sequence
  """

  use Farmbot.Sync.Database
  require Logger
  use GenServer
  alias Farmbot.CeleryScript.Ast
  alias SequenceRunner.Binding
  use Counter, __MODULE__

  defmodule State do
    defstruct [:binding, :body, :current]
  end

  @doc """
    Starts a sequence.
  """
  def start_link(%Ast{} = seq), do: GenServer.start_link(__MODULE__, seq)

  def start_link(sequence) do
    IO.puts "blerp"
    sequence = Ast.parse(sequence)
    start_link(sequence)
  end

  def init(%Ast{} = sequence) do
    Logger.debug "initializing a sequence."
    {:ok, binding} = Binding.start_link()
    body = Enum.map(sequence.body, fn(ast) ->
      ast
    end)
    current = do_work(body, self())
    state = %State{binding: binding, body: body, current: current}
    {:ok, state}
  end

  def handle_call({:next, []}, _from, state) do
    reset_count()
    {:stop, :normal, :ok, state}
  end

  def handle_call({:next, body}, _, state) do
    current = do_work(body, self())
    {:reply, :ok, %{state | body: body, current: current}}
  end

  def handle_call({:stop, reason}, _, state) do
    {:stop, reason, :ok, state}
  end

  defp do_work(body, pid) do
    spawn(__MODULE__, :work, [body, pid])
  end

  def work([item | rest], pid) do
    inc_count()
    if get_count() > 1_000 do
      :ok = GenServer.call(pid, {:stop, :recursing})
    else
      Logger.debug "doing #{item.kind}"
      Farmbot.CeleryScript.Command.do_command(item)
      :ok = GenServer.call(pid, {:next, rest})
    end
  end

  def terminate(reason, state) do
    if reason != :normal do
      Logger.error(">> Sequence died! #{inspect reason}")
    end
    :ok = Binding.stop(state.binding)
  end
end
