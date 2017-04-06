defmodule Farmbot.SequenceRunner do
  @moduledoc """
    Runs a sequence
  """
  use GenServer
  alias Farmbot.CeleryScript.Ast
  import Farmbot.CeleryScript.Command, only: [do_command: 1]
  require Logger

  def start_link(ast) do
    GenServer.start_link(__MODULE__, ast, [])
  end

  def wait(sequence), do: GenServer.call(sequence, :wait, :infinity)

  def init(ast) do

    context = ast.args[:context] || %{parent: nil}

    IO.inspect context

    ast = traverse(ast, context)
    [first | rest] = ast.body
    spawn __MODULE__, :work, [first, self()]
    {:ok, %{blocks: [], body: rest}}
  end

  def handle_call(:wait, from, state) do
    {:noreply, %{state | blocks: [from | state.blocks]}}
  end

  def handle_cast(:finished, %{body: []} = state) do
    for from <- state.blocks do
      GenServer.reply(from, :ok)
    end
    {:stop, :normal, []}
  end

  def handle_cast(:finished, %{body: rest} = state) do
    [first | rest] = rest
    spawn __MODULE__, :work, [first, self()]
    {:noreply, %{state | body: rest}}
  end

  def work(ast, sequence) do
    do_command(ast)
    GenServer.cast(sequence, :finished)
  end

  defp traverse(ast, context)

  defp traverse(%{args: args, body: body} = ast, context) do
    args = traverse_args(args, context)
    body = traverse_body(body, context)
    %Ast{ast | args: args, body: body} |> intercept_ast(context)
  end

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

  # body traversal
  defp traverse_body(body, context, acc \\ [])

  # When we finish, make sure to reverse the list otherwise its backwards
  defp traverse_body([], _context, acc), do: acc |> Enum.reverse

  defp traverse_body([item | rest], context, acc) do
    item = item |> traverse(context) |> intercept_item(context)
    traverse_body(rest, context, [item | acc])
  end

  defp intercept_arg({_key, _value} = arg, _context) do
    # IO.puts "arg: #{inspect arg}"
    arg
  end

  defp intercept_item(item, _context) do
    # IO.puts "item: #{inspect item}"
    item
  end

  # inject a new context into execute blocks for the next sequence to use.
  defp intercept_ast(%{kind: "execute"} = ast, _context) do
    context = new_context()
    IO.puts "replacing context: #{inspect context}"
    %{ast | args: Map.put(ast.args, :context, context)}
  end

  defp intercept_ast(%{kind: "call_parent"} = ast, context) do
    IO.puts "replacing context: #{inspect context}"
    %{ast | args: Map.put(ast.args, :context, context)}
  end

  defp intercept_ast(ast, _context) do
    ast
  end

  defp new_context, do: %{parent: self()}

  def s do
    # %Farmbot.CeleryScript.Ast{args: %{is_outdated: false, version: 4},
    #  body: [%Farmbot.CeleryScript.Ast{args: %{message: "SHOULD HAPPEN FIRST!",
    #      message_type: "success"}, body: [], comment: nil, kind: "send_message"},
    #   %Farmbot.CeleryScript.Ast{args: %{_else: %Farmbot.CeleryScript.Ast{args: %{},
    #       body: [], comment: nil, kind: "nothing"},
    #      _then: %Farmbot.CeleryScript.Ast{args: %{sequence_id: 297}, body: [],
    #       comment: nil, kind: "execute"}, lhs: "x", op: "is", rhs: 0}, body: [],
    #    comment: nil, kind: "_if"},
    #   %Farmbot.CeleryScript.Ast{args: %{message: "SHOULD HAPPEN LAST!",
    #      message_type: "success"}, body: [], comment: nil, kind: "send_message"}],
    #  comment: nil, kind: "sequence"}
    %Farmbot.CeleryScript.Ast{args: %{is_outdated: false, version: 4},
    body: [
      %Farmbot.CeleryScript.Ast{args: %{message: "SHOULD HAPPEN FIRST!", message_type: "success"}, body: [], comment: nil, kind: "send_message"},
      %Farmbot.CeleryScript.Ast{args: %{_else: %Farmbot.CeleryScript.Ast{args: %{}, body: [], comment: nil, kind: "nothing"},
                                        _then: %Farmbot.CeleryScript.Ast{args: %{sequence_id: 297}, body: [], comment: nil, kind: "execute"},
                                        lhs: "x", op: "is", rhs: 0}, body: [],
                                comment: nil,
                                kind: "_if"},
      %Farmbot.CeleryScript.Ast{args: %{message: "SHOULD HAPPEN LAST!", message_type: "success"}, body: [], comment: nil, kind: "send_message"},
      %Farmbot.CeleryScript.Ast{args: %{}, body: [], comment: nil, kind: "call_parent"}
      ],
    comment: nil, kind: "sequence"}
  end

end
