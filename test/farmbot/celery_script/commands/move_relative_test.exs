defmodule Farmbot.CeleryScript.Command.MoveRelativeTest do
  alias Farmbot.CeleryScript.Command
  use Farmbot.Test.Helpers.SerialTemplate, async: false
  require IEx

  describe "move_absolute" do
    test "makes sure we have serial", %{cs_context: context} do
      assert Farmbot.Serial.Handler.available?(context) == true
    end

    test "moves to a location", %{cs_context: context} do
      [_, _, _] = Farmbot.BotState.set_pos(context, 500,0,0)
      [oldx, oldy, oldz] = Farmbot.BotState.get_current_pos(context)

      Command.move_relative(%{speed: 800, x: 100, y: 0, z: 0}, [], context)
      Process.sleep(600)
      [newx, newy, newz] = Farmbot.BotState.get_current_pos(context)
      assert newx == (oldx + 100)
      assert newy == oldy
      assert newz == oldz
    end
  end
end
