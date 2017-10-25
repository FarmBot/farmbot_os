defmodule Farmbot.CeleryScript.AST.Compiler do
  @moduledoc false

  require Logger

  alias Farmbot.CeleryScript.AST
  alias Farmbot.CeleryScript.AST.Compiler.CompileError
  alias Farmbot.CeleryScript.VirtualMachine.InstructionSet

  defmodule SnapShot do
    @moduledoc false
    defstruct [count: 0, points: %{}, sequences: %{}, tools: %{}]

    def add(node, snapshot) do
      apply(__MODULE__, :"#{node.kind}", [node, snapshot])
    end

    def point(node, snapshot) do
      count_and_add_to(snapshot, :points, :pointer_id, node)
    end

    def execute(node, snapshot) do
      count_and_add_to(snapshot, :sequences, :sequence_id, node)
    end

    def tool(node, snapshot) do
      count_and_add_to(snapshot, :tools, :tool_id, node)
    end

    def count_and_add_to(snapshot, collection_name, arg_name, node) do
      id = node.args[arg_name] || raise "no id"
      collection = Map.get(snapshot, collection_name) || raise "no collection"
      case collection[id] do
        nil ->
          snapshot
          |> Map.put(:count, snapshot.count + 1)
          |> Map.put(collection_name, Map.put(collection, id, node))
        _ -> snapshot
      end
    end
  end

  defmodule Freezer do
    def climb(node, snapshot, callback) do
      go(node, snapshot, callback)
    end

    def go(%AST{kind: kind, args: args, body: body} = node, snapshot, callback) do
      {node, snapshot} = maybe_freeze(node, snapshot, callback)
      {body, snapshot} = Enum.reduce(node.body, {[], snapshot}, fn(sub_ast, {body, snapshot}) ->
        {node, snapshot} = maybe_freeze(sub_ast, snapshot, callback)
        {body ++ [node], snapshot}
      end)
      {%{node | body: body}, snapshot}
    end

    def maybe_freeze(node, snapshot, callback) do
      if node.kind in ["execute", "point", "tool"] do
        snapshot = apply(SnapShot, callback, [node, snapshot])
        {node, snapshot}
      else
        {node, snapshot}
      end
    end
  end

  def compile(ast, %InstructionSet{} = instruction_set, snapshot \\ nil) do
    snapshot = snapshot || struct(SnapShot)
    starting = snapshot.count
    {ast, snapshot} = Freezer.climb(ast, snapshot, :add)
    ending = snapshot.count
    if (ending > starting && ending != 0) do
      fetch_sequences(instruction_set, snapshot, Map.keys(snapshot.sequences))
    else
      IO.puts "stop recursion."
      snapshot
    end
  end

  def fetch_sequences(instruction_set, snapshot, []) do
    snapshot
  end

  def fetch_sequences(instruction_set, snapshot, [id | rest]) do
    replace_me = Map.get(snapshot.sequences, id) || raise "no sequencce: #{id}"
    if replace_me.kind == "execute" do
      IO.puts "replacing: #{inspect replace_me}"
      seq_ast = Farmbot.HTTP.get!("/api/sequences/#{replace_me.args.sequence_id}").body |> Poison.decode! |> Farmbot.CeleryScript.AST.parse
      sequences = %{snapshot.sequences | id => seq_ast}
      snapshot = compile(seq_ast, instruction_set, %{snapshot | sequences: sequences})
      fetch_sequences(instruction_set, snapshot, rest)
    else
      fetch_sequences(instruction_set, snapshot, rest)
    end
  end

end

# Farmbot.HTTP.get!("/api/sequences/2") |> Map.get(:body) |> Poison.decode! |> Farmbot.CeleryScript.AST.parse |> Farmbot.CeleryScript.VirtualMachine.execute
