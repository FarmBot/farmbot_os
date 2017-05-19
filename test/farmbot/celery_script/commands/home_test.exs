defmodule Farmbot.CeleryScript.Command.HomeTest do
  use Farmbot.Test.Helpers.SerialTemplate, async: false


  alias Farmbot.CeleryScript.Command

  describe "home" do
    test "makes sure we have serial", %{cs_context: context} do
      assert Farmbot.Serial.Handler.available?(context) == true
    end

    test "homes all axises", %{cs_context: context} do
      Command.home(%{axis: "all"}, [], context)
      Process.sleep(500)
      [x, y, z] = Farmbot.BotState.get_current_pos(context)
      assert x == 0
      assert y == 0
      assert z == 0
      Process.sleep(500)
    end

    test "homes x", %{cs_context: context} do
      [_, _, _] = Farmbot.BotState.set_pos(context, 0,0,0)
      [_x, y, z] = Farmbot.BotState.get_current_pos(context)
      Command.home(%{axis: "x"}, [], context)
      Process.sleep(500)
      [new_x, new_y, new_z] = Farmbot.BotState.get_current_pos(context)
      assert new_x == 0
      assert y == new_y
      assert z == new_z
    end

    test "homes y", %{cs_context: context} do
      [_, _, _] = Farmbot.BotState.set_pos(context, 0,0,0)
      [x, _y, z] = Farmbot.BotState.get_current_pos(context)
      Command.home(%{axis: "y"}, [], context)
      Process.sleep(500)
      [new_x, new_y, new_z] = Farmbot.BotState.get_current_pos(context)
      assert x == new_x
      assert new_y == 0
      assert z == new_z
    end

    test "homes z", %{cs_context: context} do
      [_, _, _] = Farmbot.BotState.set_pos(context, 0,0,0)
      [x, y, _z] = Farmbot.BotState.get_current_pos(context)
      Command.home(%{axis: "z"}, [], context)
      Process.sleep(500)
      [new_x, new_y, new_z] = Farmbot.BotState.get_current_pos(context)
      assert x == new_x
      assert y == new_y
      assert new_z == 0
    end
  end


end
