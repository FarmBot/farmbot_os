defmodule Farmbot.CeleryScript.Command.PowerOffTest do
  use ExUnit.Case, async: false
  alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command

  import Mock

  test "powers off the bot" do
    with_mock Farmbot.System, [power_off: fn() -> :ok end] do
      json = ~s"""
      {
        "kind": "power_off",
        "args": {}
      }
      """
      ast = json |> Poison.decode!() |> Ast.parse

      Command.do_command(ast)
      assert called Farmbot.System.power_off
    end

  end
end
