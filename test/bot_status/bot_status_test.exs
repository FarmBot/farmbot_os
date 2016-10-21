ExUnit.start
defmodule BotStateTest do
  use ExUnit.Case, async: true

  test "gets the current status" do
    {:ok, status} = BotState.init(:hello)
    {:reply, current_status, current_status} = BotState.handle_call({:get_status}, self(), status)
    # We havent changed anything so the status should be in its initial state.
    assert(status == current_status)
    # just a sanity check
    assert(Map.get(current_status, :busy) == true)
  end

  test "sets a pin value on and then off again." do
    BotState.set_pin(13, 1)

    status1 = BotState.get_status
    assert(Map.get(status1, "pin13") == 1)

    BotState.set_pin(13, 0)
    status2 = BotState.get_status
    assert(Map.get(status2, "pin13") == 0)
    assert(BotState.get_pin(13) == 0)
  end

  test "checks and Sets busy" do
    status = BotState.get_status
    assert(Map.get(status, :busy) == true)
    BotState.busy false
    assert(BotState.busy? == false)
  end

  test "checks and sets bot position" do
    assert(BotState.get_current_pos == [0,0,0])
    BotState.set_pos(1,2,3)
    assert(BotState.get_current_pos == [1,2,3])

    # set just x
    BotState.set_pos({:x, 55})
    assert(BotState.get_current_pos == [55,2,3])

    BotState.set_pos({:y, 15000})
    assert(BotState.get_current_pos == [55,15000,3])

    BotState.set_pos({:z, -45})
    assert(BotState.get_current_pos == [55,15000,-45])
  end

  test "gets the current version" do
    version = Path.join(__DIR__ <> "/../../", "VERSION")
              |> File.read!
              |> String.strip
    assert(BotState.get_current_version == version)
  end
end
