defmodule FarmbotCore.FirmwareEstopTimerTest do
  use ExUnit.Case
  alias FarmbotCore.FirmwareEstopTimer

  test "calls a function in X MS" do
    test_pid = self()
    timeout_ms = :rand.uniform(20)

    timeout_function = fn ->
      send(test_pid, :estop_timer_message)
    end

    args = [timeout_function: timeout_function, timeout_ms: timeout_ms]
    {:ok, pid} = FirmwareEstopTimer.start_link(args, [])
    _timer = FirmwareEstopTimer.start_timer(pid)
    assert_receive :estop_timer_message, timeout_ms + 5
  end

  test "doesn't call function if canceled" do
    timeout_ms = :rand.uniform(20)
    test_pid = self()

    timeout_function = fn ->
      send(test_pid, :estop_timer_message)
      flunk("This function should never be called")
    end

    args = [timeout_function: timeout_function, timeout_ms: timeout_ms]
    {:ok, pid} = FirmwareEstopTimer.start_link(args, [])
    timer = FirmwareEstopTimer.start_timer(pid)
    ^timer = FirmwareEstopTimer.cancel_timer(pid)
    refute_receive :estop_timer_message
  end
end
