defmodule Farmbot.CeleryScript.Command.NothingTest do
  use ExUnit.Case
  alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command
  test "does nothing" do
    json = ~s"""
    {
      "kind": "nothing",
      "args": {}
    }
    """
    ast = json |> Poison.decode!() |> Ast.parse
    r = Command.do_command(ast)
    assert r.kind == "nothing"
  end
end
