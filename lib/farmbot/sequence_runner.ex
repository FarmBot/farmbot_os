defmodule Farmbot.SequenceRunner do
  @moduledoc """
    Runs a sequence
  """
  use GenServer
  alias Farmbot.CeleryScript.Ast
  import Farmbot.CeleryScript.Command, only: [do_command: 1]
  require Logger

  @typedoc """
    This gets injected into the args of a sequence, and all of its children etc.
    Mostly magic.
  """
  @type context :: %{parent: pid | nil}
  @type sequence_pid :: pid

  @type block :: {reference, pid}

  @type state :: %{
    blocks: [block],
    body: [Ast.t]
  }

  @doc """
    Starts a sequence.
  """
  def start_link(ast) do
    GenServer.start_link(__MODULE__, ast, [])
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

  def init(ast) do
    # if there is no previous context, build a new one
    context = ast.args[:context] || empty_context()

    # travers the ast, compile some stuff, validate some stuff etc.
    ast = traverse(ast, context)

    # Setup the firt step
    [first | rest] = ast.body
    spawn __MODULE__, :work, [first, self()]

    {:ok, %{blocks: [], body: rest}}
  end

  # This is a validation for if a sequence has a parent or not.
  def handle_call({:call, :ping}, _, state) do
    {:reply, :pong, state}
  end

  # Block til _this_ sequence finishes.
  def handle_call(:wait, from, state) do
    {:noreply, %{state | blocks: [from | state.blocks]}}
  end

  # When a stop finishes and there is no more steps
  def handle_cast(:finished, %{body: []} = state) do
    # Tell all things involved that this sequence is done.
    :ok = reply_blocks(:ok, state.blocks)
    {:stop, :normal, %{state | blocks: []}}
  end

  def handle_cast(:finished, %{body: rest} = state) do
    [first | rest] = rest
    spawn __MODULE__, :work, [first, self()]
    {:noreply, %{state | body: rest}}
  end

  # if we terminate for any non normal reason, make sure to reply
  # to any blocks we had.
  def terminate(reason, state) do
    unless reason == :normal do
      :ok = reply_blocks(reason, state.blocks)
    end
    :ok
  end

  @spec work(Ast.t, sequence_pid) :: :ok
  def work(ast, sequence) do
    # This sleep makes sequences more stable and makes sure
    # The bot was _actualy_ complete with the last command in real life.
    Process.sleep(500)
    do_command(ast)
    GenServer.cast(sequence, :finished)
  end

  @typedoc """
    Deconstructed ast node arg
  """
  @type arg :: {String.t, String.t | Ast.t}

  @typedoc """
    I don't remember what this is.
  """
  @type item :: any

  @spec traverse(Ast.t, context) :: Ast.t
  defp traverse(ast, context)

  defp traverse(%{args: args, body: body} = ast, context) do
    args = traverse_args(args, context)
    body = traverse_body(body, context)
    %Ast{ast | args: args, body: body} |> intercept_ast(context)
  end

  @spec traverse_args(map | [arg], context, [arg]) :: map
  # traverse the k/v version of the args.
  defp traverse_args(args, context, acc \\ [])

  defp traverse_args(%{} = args, context, []), do: traverse_args(Map.to_list(args), context, [])

  # Turn it back into a map when we are done.
  defp traverse_args([], _context, acc), do: Map.new(acc)

  defp traverse_args([{key, value} | rest], context, acc) do
    value = if match?(%Ast{}, value) do
      traverse(value, context)
    else
      value
    end
    arg = intercept_arg({key, value}, context)
    traverse_args(rest, context, [arg | acc])
  end

  @spec traverse_body([item], context, [item]) :: [item]
  # body traversal
  defp traverse_body(body, context, acc \\ [])

  # When we finish, make sure to reverse the list otherwise its backwards
  defp traverse_body([], _context, acc), do: acc |> Enum.reverse

  defp traverse_body([item | rest], context, acc) do
    item = item |> traverse(context) |> intercept_item(context)
    traverse_body(rest, context, [item | acc])
  end

  @spec intercept_arg(arg, context) :: arg
  defp intercept_arg({_key, _value} = arg, _context), do: arg

  @spec intercept_item(item, context) :: item
  defp intercept_item(item, _context), do: item

  @spec intercept_ast(Ast.t, context) :: Ast.t
  # inject a new context into execute blocks for the next sequence to use.
  defp intercept_ast(%{kind: "execute"} = ast, _context) do
    context = new_context()
    %{ast | args: Map.put(ast.args, :context, context)}
  end

  # inject context into nodes other nodes
  defp intercept_ast(ast, context),
    do: %{ast | args: Map.put(ast.args, :context, context)}

  @spec reply_blocks(term, [block]) :: any
  defp reply_blocks(reply, blocks) do
    for from <- blocks do
      :ok = GenServer.reply(from, reply)
    end
    :ok
  end

  @spec new_context :: context
  defp new_context, do: %{parent: self()}
  @spec empty_context :: context
  defp empty_context, do: %{parent: nil}

end
