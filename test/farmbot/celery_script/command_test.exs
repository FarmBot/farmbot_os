defmodule CommandTest do
  use ExUnit.Case, async: false
  alias Farmbot.CeleryScript.{Command, Ast}

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

  test "converts a coordinate to coordinates", %{cs_context: context} do
    # a coordinate is already a coordinate
    ast_a   = %Ast{kind: "coordinate", args: %{x: 1, y: 1, z: 1}, body: []}
    context = Command.ast_to_coord(context, ast_a)
    {coord_a, next_context} = Farmbot.Context.pop_data(context)

    assert is_map(coord_a)

    assert is_map(next_context)

    assert ast_a.kind == coord_a.kind
  end

  # test "converts a tool to a coodinate" do
  #   use Amnesia
  #   use ToolSlot
  #   use Tool
  #   x = 1
  #   y = 2
  #   z = 3
  #   tool_slot = %ToolSlot{id: 503, tool_id: 97, name: "uh", x: 1, y: 2, z: 3}
  #   |> ToolSlot.write
  #
  #   tool = %Tool{id: 97, name: "lazer"} |> Tool.write
  #
  #   # {tool_slot, tool}
  #
  #   ast = %Ast{kind: "tool", args: %{tool_id: 97}, body: []}
  #   coord = Command.ast_to_coord(ast)
  #   coord_x = coord.args.x
  #   assert coord_x == x
  #   assert coord_x == tool_slot.x
  #
  #   coord_z = coord.args.z
  #   assert coord_z == z
  #   assert coord_z == tool_slot.z
  #
  #   coord_y = coord.args.y
  #   assert coord_y == y
  #   assert coord_y == tool_slot.y
  #
  #   bad_tool = %Ast{kind: "tool", args: %{tool_id: 98}, body: []}
  #   r = Command.ast_to_coord(bad_tool)
  #   assert r == :error
  # end

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
