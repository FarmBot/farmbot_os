ExUnit.start
defmodule BotStatusTest do
  use ExUnit.Case, async: true

  test "gets the current status" do
    {:ok, status} = BotStatus.init(:hello)
    {:reply, current_status, current_status} = BotStatus.handle_call({:get_status}, self(), status)
    # We havent changed anything so the status should be in its initial state.
    assert(status == current_status)
    # just a sanity check
    assert(Map.get(current_status, :busy) == true)
  end

  test "sets a pin value on and then off again." do
    BotStatus.set_pin(13, 1)

    status1 = BotStatus.get_status
    assert(Map.get(status1, "pin13") == 1)

    BotStatus.set_pin(13, 0)
    status2 = BotStatus.get_status
    assert(Map.get(status2, "pin13") == 0)
    assert(BotStatus.get_pin(13) == 0)
  end

  test "checks and Sets busy" do
    status = BotStatus.get_status
    assert(Map.get(status, :busy) == true)
    BotStatus.busy false
    assert(BotStatus.busy? == false)
  end

  test "checks and sets bot position" do
    assert(BotStatus.get_current_pos == [0,0,0])
    BotStatus.set_pos(1,2,3)
    assert(BotStatus.get_current_pos == [1,2,3])

    # set just x
    BotStatus.set_pos({:x, 55})
    assert(BotStatus.get_current_pos == [55,2,3])

    BotStatus.set_pos({:y, 15000})
    assert(BotStatus.get_current_pos == [55,15000,3])

    BotStatus.set_pos({:z, -45})
    assert(BotStatus.get_current_pos == [55,15000,-45])
  end

  test "gets the current version" do
    version = Path.join(__DIR__ <> "/../../", "VERSION")
              |> File.read!
              |> String.strip
    assert(BotStatus.get_current_version == version)
  end
end
