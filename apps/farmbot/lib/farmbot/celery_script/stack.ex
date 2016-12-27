defmodule Farmbot.CeleryScript.Stack do
  @moduledoc """
    Manages celeryscript command execution.
  """
  use GenServer
  require Logger
  alias Farmbot.CeleryScript.Ast

  defmodule State do
    @moduledoc false
    @enforce_keys [:stack]
    defstruct @enforce_keys
  end

  def init(args) do
    :timer.apply_after(100, __MODULE__, :tick, [self])
    {:ok, %State{stack: []}}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def terminate(reason, state) do
    Logger.debug ">> CeleryScript stack terminated!"
  end

  @doc """
    Pushes a celeryscript node onto the stack.
  """
  @spec push(Ast.t) :: :ok | {:error, atom}
  def push(%Ast{} = ast_node), do: GenServer.cast(__MODULE__, {:push, ast_node})

  def handle_cast({:push, ast_node}, %State{} = state) do
    # puts a new node at the top of the stack
    {:noreply, %State{state | stack: [ast_node | state.stack]}}
  end

  def handle_cast(:tick, %State{} = state) do
    {:noreply, handle_tick(state)}
  end

  defp handle_tick(%State{} = state) do
    # take the last item off the stack
    new_stack = Enum.drop(state.stack, -1)
    # grab the ast node we are going to execute
    thing = List.last(state.stack)
    %State{state | stack: new_stack}
  end

  def tick(pid) do
    GenServer.cast(pid, :tick)
  end
end
