defmodule FarmbotOS.Lua.PinWatcherTest do
  alias FarmbotOS.Firmware.UARTCore
  alias FarmbotOS.Lua.PinWatcher
  use ExUnit.Case
  use Mimic
  setup :set_mimic_global
  setup :verify_on_exit!

  test "lifecycle I" do
    expect(UARTCore, :watch_pin, 1, fn pin ->
      assert pin == 54
      :ok
    end)

    test_fn = fn arg -> assert arg == "?" end
    assert {[], :lua} == PinWatcher.new([54, test_fn], :lua)
  end

  test "lifecycle II" do
    expect(UARTCore, :watch_pin, 1, fn pin ->
      assert pin == 54
      :ok
    end)

    test_fn = fn arg ->
      assert arg == [[pin: 54, value: 45]]
    end

    {:ok, pid} = GenServer.start_link(PinWatcher, [54, test_fn, self()])
    send(pid, {:pin_data, 54, 45})
    Process.exit(pid, :normal)
    Process.sleep(100)
  end

  test "parent PID no longer responding" do
    pid = spawn(fn -> :dead_pid end)
    Process.sleep(100)

    state = %{
      parent: pid,
      callback: fn _ -> raise "Should never execute" end
    }

    message = {:pin_data, 54, 45}
    resp = PinWatcher.handle_info(message, state)
    assert resp == {:stop, :normal, state}
  end

  test "termination" do
    expect(UARTCore, :unwatch_pin, 1, fn -> :ok end)
    PinWatcher.terminate(:_, :_)
  end
end
