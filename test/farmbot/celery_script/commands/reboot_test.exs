defmodule Farmbot.CeleryScript.Command.RebootTest do
  use ExUnit.Case, async: false
  alias Farmbot.CeleryScript.{Command, Ast}

  test "reboots the bot" do
    json = ~s"""
    {
      "kind": "reboot",
      "args": {}
    }
    """
    ast = json |> Poison.decode!() |> Ast.parse
    new_context = Command.do_command(ast, Farmbot.Context.new())
    assert new_context
  end
end
