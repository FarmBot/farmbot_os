defmodule Farmbot.CeleryScript.Command.NothingTest do
  use ExUnit.Case
  alias Farmbot.CeleryScript.{Command, Ast}

  test "does nothing" do
    json = ~s"""
    {
      "kind": "nothing",
      "args": {}
    }
    """
    ast = json |> Poison.decode!() |> Ast.parse
    context = Command.do_command(ast, Ast.Context.new())
    {r, _final_context} = Ast.Context.pop_data(context)
    assert is_map(r)
    assert r.kind == "nothing"
  end
end
