defmodule Farmbot.SequenceRunner do
  @moduledoc """
    Runs a sequence
  """
  use     GenServer
  alias   Farmbot.{CeleryScript, Context, DebugLog}
  alias   CeleryScript.Ast
  import  CeleryScript.Command, only: [do_command: 2]
  require Logger
  use     DebugLog

  @typedoc """
    This gets injected into the args of a sequence, and all of its children etc.
    Mostly magic.
  """
  @type context :: Ast.context
  @type sequence_pid :: pid

  @type block :: {reference, pid}

  @type state :: %{
    blocks: [block],
    body: [Ast.t]
  }

  @doc """
    Starts a sequence.
  """
  def start_link(%Ast{} = ast, %Context{} = ctx) do
    GenServer.start_link(__MODULE__, {ast, ctx}, [])
  end

  @doc """
    Wait for thie sequence
  """
  @spec wait(sequence_pid) :: :ok | term
  def wait(sequence), do: GenServer.call(sequence, :wait, :infinity)

  @doc """
    Call a sequence
  """
  @spec call(sequence_pid, any) :: any
  def call(sequence, call), do: GenServer.call(sequence, {:call, call})

  def init({ast, first_context}) do
    debug_log "[#{inspect self()}] Sequence init."
    # Setup the firt step
    [first | rest] = ast.body
    spawn __MODULE__, :work, [{first, first_context}, self()]

    {:ok, %{blocks: [], body: rest, context: first_context}}
  end

  # Block til _this_ sequence finishes.
  def handle_call(:wait, from, state) do
    debug_log "[#{inspect self()}] beginning wait."
    {:noreply, %{state | blocks: [from | state.blocks]}}
  end

  # When a stop finishes and there is no more steps
  def handle_cast({:finished, next_context}, %{body: []} = state) do
    # Tell all things involved that this sequence is done.
    :ok = reply_blocks(state.blocks, next_context)
    {:stop, :normal, %{state | blocks: [], context: next_context}}
  end

  def handle_cast({:finished, next_context}, %{body: rest} = state) do
    [first | rest] = rest
    spawn __MODULE__, :work, [{first, next_context}, self()]
    {:noreply, %{state | body: rest, context: next_context}}
  end

  # if we terminate for any non normal reason, make sure to reply
  # to any blocks we had.
  def terminate(_reason, state) do
    debug_log "[#{inspect self()}] Sequence Exiting."
    :ok = reply_blocks(state.blocks, state.context)
  end

  @spec work(Ast.t, sequence_pid) :: :ok
  def work({ast, context}, sequence) do
    debug_log "[#{inspect self()}] doing work: #{inspect ast}"
    # This sleep makes sequences more stable and makes sure
    # The bot was _actualy_ complete with the last command in real life.
    Process.sleep(500)
    next_context = do_command(ast, context)
    GenServer.cast(sequence, {:finished, next_context})
  end

  @spec reply_blocks([block], context) :: :ok
  defp reply_blocks(blocks, context) do
    for from <- blocks do
      :ok = GenServer.reply(from, context)
    end
    :ok
  end
end
