ExUnit.start
defmodule BotStateTest do
  use ExUnit.Case, async: true

  test "gets the current status" do
    # We drop the authorization key/value pair because the state handle call drops it.
    {:ok, with_auth_status} = BotState.init(:normal)
    status = with_auth_status |> Map.drop([:authorization])
    {:reply, current_status, current_status} = BotState.handle_call(:state, self(), status)
    # We havent changed anything so the status should be in its initial state.
    assert(status == current_status)
  end

  test "sets a pin value on and then off again." do
    BotState.set_pin_mode(13, 0)
    BotState.set_pin_value(13, 1)

    a = BotState.get_pin(13)
    assert(a == %{mode: 0, value: 1})

    BotState.set_pin_value(13, 0)
    b = BotState.get_pin(13)
    assert(b == %{mode: 0, value: 0})
  end

  test "checks and sets bot position" do
    assert(BotState.get_current_pos == [0,0,0])
    BotState.set_pos(1,2,3)
    assert(BotState.get_current_pos == [1,2,3])
  end

  test "updates a configuration key that DOES exist." do
    # keys that exist should return true
    update_bool = BotState.update_config("os_auto_update", false)
    q = BotState.get_config(:os_auto_update)
    assert(update_bool == true)
    assert(q == false)
  end

  test "updates a configuration key that DOES NOT exist." do
    # keys that don't exist should return false
    update_bool = BotState.update_config("check_email_time", 15000)
    q = BotState.get_config(:check_email_time)
    assert(q == nil)
    assert(update_bool == false)
  end

  test "updates a configuration key that DOES exist but the type is bad." do
    # Before we try to update it.
    old = BotState.get_config(:os_auto_update)
    # should return false
    update_bool = BotState.update_config("os_auto_update", "silly_string")
    new = BotState.get_config(:os_auto_update)
    assert(old == new)
    assert(update_bool == false)
  end
end
