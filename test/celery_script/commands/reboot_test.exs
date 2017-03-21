defmodule Farmbot.CeleryScript.Command.RebootTest do
  use ExUnit.Case, async: false
  alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command

  import Mock

  test "reboots the bot" do
    with_mock Farmbot.System, [reboot: fn() -> :ok end] do
      json = ~s"""
      {
        "kind": "reboot",
        "args": {}
      }
      """
      ast = json |> Poison.decode!() |> Ast.parse

      Command.do_command(ast)
      assert called Farmbot.System.reboot
    end

  end
end
