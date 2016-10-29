ExUnit.start
defmodule BotStateTest do
  use ExUnit.Case, async: true

  test "gets the current status" do
    {:ok, status} = BotState.init(:normal)
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
end
