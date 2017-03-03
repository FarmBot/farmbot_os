defmodule CommandTest do
  use ExUnit.Case
  alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command
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
end
