defmodule Farmbot.CeleryScript.Command.MoveRelativeTest do
  use ExUnit.Case, async: false
  alias Farmbot.CeleryScript.Command
  import Farmbot.Test.SerialHelper, only: [setup_serial: 0, teardown_serial: 3]

  setup do
    {handf, slot, context} = setup_serial()
    %{cs_context: context, slot: slot, handf: handf}
  end

  test "makes sure we have serial", %{cs_context: context, slot: slot, handf: handf} do
    assert Farmbot.Serial.Handler.available?(context.serial) == true
    teardown_serial(slot, context, handf)
  end

  test "moves to a location", %{cs_context: context, slot: slot, handf: handf} do
    [oldx, oldy, oldz] = Farmbot.BotState.get_current_pos

    Command.move_relative(%{speed: 800, x: 100, y: 0, z: 0}, [], context)
    Process.sleep(1000) # wait for serial to catch up
    [newx, newy, newz] = Farmbot.BotState.get_current_pos
    assert newx == oldx + 100
    assert newy == oldy
    assert newz == oldz
    teardown_serial(slot, context, handf)

  end
end
