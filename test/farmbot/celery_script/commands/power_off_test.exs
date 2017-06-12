defmodule Farmbot.CeleryScript.Command.PowerOffTest do
  use ExUnit.Case, async: false
  alias Farmbot.CeleryScript.{Command, Ast}

  test "powers off the bot" do
    json = ~s"""
    {
      "kind": "power_off",
      "args": {}
    }
    """
    ast = json |> Poison.decode!() |> Ast.parse
    new_context = Command.do_command(ast, Farmbot.Context.new())
    assert new_context
  end
end
