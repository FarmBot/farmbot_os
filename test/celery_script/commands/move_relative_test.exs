defmodule Farmbot.CeleryScript.Command.MoveRelativeTest do
  use ExUnit.Case
  alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command

  setup_all do
    GcodeMockTest.common_setup()
  end

  test "makes sure we have serial", %{handler: handler} do
    assert is_pid(handler)
    assert Farmbot.Serial.Handler.available?(handler) == true
  end

  test "moves to a location" do
    [oldx, oldy, oldz] = Farmbot.BotState.get_current_pos

    Command.move_relative(%{speed: 800, x: 100, y: 0, z: 0}, [])

    [newx, newy, newz] = Farmbot.BotState.get_current_pos
    assert newx == oldx + 100
    assert newy == oldy
    assert newz == oldz
  end
end
