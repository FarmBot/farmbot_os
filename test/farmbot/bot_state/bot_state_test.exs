defmodule Farmbot.BotStateTest do
  require IEx
  use ExUnit.Case, async: false

  test("Gets the current bot position") do
    [x,y,z] = Farmbot.BotState.get_current_pos
    assert(is_integer(x) and is_integer(y) and is_integer(z))
  end

  test("Sets a new position") do
    Farmbot.BotState.set_pos(45, 123, -666)
    [x,y,z] = Farmbot.BotState.get_current_pos
    assert(x == 45)
    assert(y == 123)
    assert(z == -666)
  end

  test "sets a pin mode" do
    Farmbot.BotState.set_pin_mode(123, 0)
    %{mode: mode, value: _} = Farmbot.BotState.get_pin(123)
    assert(mode == 0)
  end

  test "sets a pin value" do
    Farmbot.BotState.set_pin_value(123, 55)
    %{mode: _, value: value} = Farmbot.BotState.get_pin(123)
    assert(value == 55)
  end

  test "updates a config" do
    Farmbot.BotState.update_config("os_auto_update", false)
    val = Farmbot.BotState.get_config(:os_auto_update)
    assert(val == false)
  end

  test "sets and removes a lock" do
    Farmbot.BotState.add_lock("e_stop")
    v = Farmbot.BotState.get_lock("e_stop")
    assert(v == 0)

    Farmbot.BotState.remove_lock("e_stop")
    v = Farmbot.BotState.get_lock("e_stop")
    assert(v == nil)
  end

end
