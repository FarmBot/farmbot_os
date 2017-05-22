defmodule CommandTest do
  use ExUnit.Case, async: false
  alias Farmbot.CeleryScript.{Command, Ast}
  import Mock

  setup_all do
    [cs_context: Farmbot.Context.new()]
  end

  test "doesnt freak out on no instruction", %{cs_context: context} do
    json = ~s"""
    {
      "kind": "bring_down_network",
      "args": {"time": "now"}
    }
    """
    cs = Poison.decode!(json) |> Ast.parse()
    assert_raise RuntimeError, fn() ->
      Command.do_command(cs, context)
    end
  end

  test "rescues from bad things", %{cs_context: context} do
    with_mock Farmbot.CeleryScript.Command.Nothing, [run: fn(_,_,_) ->
      raise "Mucking About with Mocks"
    end] do
      assert_raise RuntimeError, fn() ->
        nothing_ast = %Ast{kind: "nothing", args: %{}, body: [], comment: "hey!"}
        Command.do_command(nothing_ast, context)
      end
    end
  end

  test "cant execute random data that is not a cs node", %{cs_context: context} do
    assert_raise RuntimeError, fn() ->
      Command.do_command("shut the door its cold in here!", context)
    end
  end

  test "converts a coordinate to coordinates", %{cs_context: context} do
    # a coordinate is already a coordinate
    ast_a   = %Ast{kind: "coordinate", args: %{x: 1, y: 1, z: 1}, body: []}
    context = Command.ast_to_coord(context, ast_a)
    {coord_a, next_context} = Farmbot.Context.pop_data(context)

    assert is_map(coord_a)

    assert is_map(next_context)

    assert ast_a.kind == coord_a.kind
  end

  alias Farmbot.Context
  alias Farmbot.Database
  alias Database.Syncable.Point
  alias Farmbot.CeleryScript.Ast

  test "converts a tool to a coordinate" do
    ctx = Context.new()
    {:ok, database} = Database.start_link(ctx, [])
    ctx = %{ctx | database: database}

    tool_id = 66

    point = %Point{id: 6, x: 1, y: 2, z: 3, pointer_type: "tool_slot", tool_id: tool_id}

    Database.commit_records point, ctx, Point

    tool_ast              = %Ast{kind: "tool", args: %{tool_id: tool_id}, body: []}
    new_context           = Command.ast_to_coord(ctx, tool_ast)
    {coord, _new_context2} = Context.pop_data(new_context)
    assert coord.args.x == point.x
    assert coord.args.y == point.y
    assert coord.args.z == point.z
  end

  test "raises if there is no tool_slot or something" do
    ctx        = Context.new()
    {:ok, pid} = Database.start_link(ctx, [])

    ctx = %{ctx | database: pid}

    tool_ast              = %Ast{kind: "tool", args: %{tool_id: 905}, body: []}
    assert_raise RuntimeError, "Could not find tool_slot with tool_id: 905", fn() ->
      Command.ast_to_coord(ctx, tool_ast)
    end
  end

  test "gives the origin on nothing", %{cs_context: context} do
    nothing = %Ast{kind: "nothing", args: %{}, body: []}
    {coord, context} = Command.ast_to_coord(context, nothing) |> Farmbot.Context.pop_data
    assert is_map(coord)
    assert is_map(context)
    assert coord.args.x == 0
    assert coord.args.y == 0
    assert coord.args.z == 0
  end

  test "gives an error on unknown asts", %{cs_context: context} do
    blerp = %Ast{kind: "blerp", args: %{}, body: []}
    assert_raise RuntimeError, fn ->
      Command.ast_to_coord(context, blerp)
    end
  end

  # test "doesnt implode if a sequence relies on itself" do
  #   use Amnesia
  #   use Sequence
  #
  #   real_sequence = %Sequence{args: %{"is_outdated" => false,
  #       "version" => 4},
  #     body: [%{"args" => %{"_else" => %{"args" => %{}, "kind" => "nothing"},
  #          "_then" => %{"args" => %{"sequence_id" => 40000}, "kind" => "execute"},
  #          "lhs" => "x", "op" => "not", "rhs" => 10000}, "kind" => "_if"}],
  #     color: "gray", id: 40000, kind: "sequence", name: "seq_a"}
  #
  #   Amnesia.transaction do
  #     real_sequence |> Sequence.write
  #   end
  #
  #   sequence = %Ast{kind: "execute", args: %{sequence_id: 40000}, body: []}
  #
  #   assert_raise(RuntimeError, "TO MUCH RECURSION", fn() ->
  #     Command.do_command(sequence)
  #   end)
  # end
end
