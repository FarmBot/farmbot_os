defmodule Farmbot.CeleryScript.Command.MoveAbsoluteTest do
  use ExUnit.Case, async: false

  alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command

  setup_all do
    :ok = Farmbot.Serial.HandlerTest.wait_for_serial_available()
    :ok
  end

  test "makes sure we have serial" do
    assert Farmbot.Serial.Handler.available?() == true
  end

  test "moves to a location" do
    [_curx, _cury, _curz] = Farmbot.BotState.get_current_pos
    location = %Ast{kind: "coordinate", args: %{x: 1000, y: 0, z: 0}, body: []}
    offset = %Ast{kind: "coordinate", args: %{x: 0, y: 0, z: 0}, body: []}
    Command.move_absolute(%{speed: 8000, offset: offset, location: location}, [])
    Process.sleep(100) # wait for serial to catch up
    [newx, _newy, _newz] = Farmbot.BotState.get_current_pos
    assert newx == 1000
  end

  test "moves to a location defered by an offset" do
    location = %Ast{kind: "coordinate", args: %{x: 1000, y: 0, z: 0}, body: []}
    offset = %Ast{kind: "coordinate", args: %{x: 500, y: 0, z: 0}, body: []}
    Command.move_absolute(%{speed: 8000, offset: offset, location: location}, [])
    Process.sleep(100) # wait for serial to catch up
    [newx, newy, newz] = Farmbot.BotState.get_current_pos
    assert newx == 1500
    assert newy == 0
    assert newz == 0
  end
end
