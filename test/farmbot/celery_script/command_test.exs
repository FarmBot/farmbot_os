defmodule CommandTest do
  use ExUnit.Case
  alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command
  use Farmbot.Sync.Database

  test "doesnt freak out on no instruction" do
    json = ~s"""
    {
      "kind": "bring_down_network",
      "args": {"time": "now"}
    }
    """
    cs = Poison.decode!(json) |> Ast.parse()
    r = Command.do_command(cs)
    assert r == :no_instruction
  end

  test "converts a coordinate to coordinates" do
    # a coordinate is already a coordinate
    ast_a = %Ast{kind: "coordinate", args: %{x: 1, y: 1, z: 1}, body: []}
    coord_a = Command.ast_to_coord(ast_a)
    assert ast_a.kind == coord_a.kind
  end

  test "converts a tool to a coodinate" do
    use Amnesia
    use ToolSlot
    use Tool
    x = 1
    y = 2
    z = 3
    tool_slot = %ToolSlot{id: 503, tool_id: 97, name: "uh", x: 1, y: 2, z: 3}
    |> ToolSlot.write

    tool = %Tool{id: 97, name: "lazer"} |> Tool.write

    # {tool_slot, tool}

    ast = %Ast{kind: "tool", args: %{tool_id: 97}, body: []}
    coord = Command.ast_to_coord(ast)
    coord_x = coord.args.x
    assert coord_x == x
    assert coord_x == tool_slot.x

    coord_z = coord.args.z
    assert coord_z == z
    assert coord_z == tool_slot.z

    coord_y = coord.args.y
    assert coord_y == y
    assert coord_y == tool_slot.y

    bad_tool = %Ast{kind: "tool", args: %{tool_id: 98}, body: []}
    r = Command.ast_to_coord(bad_tool)
    assert r == :error
  end

  test "gives the origin on nothing" do
    nothing = %Ast{kind: "nothing", args: %{}, body: []}
    coord = Command.ast_to_coord(nothing)
    assert coord.args.x == 0
    assert coord.args.y == 0
    assert coord.args.z == 0
  end

  test "gives an error on unknown asts" do
    blerp = %Ast{kind: "blerp", args: %{}, body: []}
    coord = Command.ast_to_coord(blerp)
    assert coord == :error
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
