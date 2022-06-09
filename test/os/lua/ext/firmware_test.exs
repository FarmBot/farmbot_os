defmodule FarmbotOS.Lua.FirmwareTest do
  alias FarmbotOS.Lua.Firmware
  alias FarmbotOS.Celery.SysCallGlue
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!

  test "calibrate/2" do
    msg = "expected stub error"
    lua = "return"

    expect(SysCallGlue, :calibrate, 2, fn
      "x" -> :ok
      _ -> {:error, msg}
    end)

    assert {[true], ^lua} = Firmware.calibrate(["x"], lua)
    assert {[nil, ^msg], ^lua} = Firmware.calibrate(["y"], lua)
  end

  test "move_absolute/2" do
    msg = "expected stub error"
    lua = "return"

    expect(SysCallGlue, :move_absolute, 4, fn
      1, _, _, _ -> :ok
      _, _, _, _ -> {:error, msg}
    end)

    assert {[true], ^lua} = Firmware.move_absolute([1, 2, 3, 4], lua)
    assert {[nil, ^msg], ^lua} = Firmware.move_absolute([5, 6, 7, 8], lua)
    assert {[true], ^lua} = Firmware.move_absolute([1, 2, 3], lua)
    assert {[nil, ^msg], ^lua} = Firmware.move_absolute([5, 6, 7], lua)
  end

  test "find_home/2" do
    msg = "expected stub error"
    lua = "return"

    expect(SysCallGlue, :find_home, 2, fn
      "x" -> :ok
      _ -> {:error, msg}
    end)

    assert {[true], ^lua} = Firmware.find_home(["x"], lua)
    assert {[nil, ^msg], ^lua} = Firmware.find_home(["y"], lua)
  end

  test "emergency_lock/2" do
    msg = "expected stub error"
    lua = "return"

    expect(SysCallGlue, :emergency_lock, 1, fn -> :ok end)
    assert {[true], ^lua} = Firmware.emergency_lock(:ok, lua)

    expect(SysCallGlue, :emergency_lock, 1, fn ->
      {:error, msg}
    end)

    assert {[nil, ^msg], ^lua} = Firmware.emergency_lock(nil, lua)
  end

  test "emergency_unlock/2" do
    msg = "expected stub error"
    lua = "return"

    expect(SysCallGlue, :emergency_unlock, 1, fn -> :ok end)
    assert {[true], ^lua} = Firmware.emergency_unlock(:ok, lua)

    expect(SysCallGlue, :emergency_unlock, 1, fn ->
      {:error, msg}
    end)

    assert {[nil, ^msg], ^lua} = Firmware.emergency_unlock(nil, lua)
  end

  test "home" do
    expect(SysCallGlue, :get_current_x, 2, fn -> 1.0 end)
    expect(SysCallGlue, :get_current_y, 2, fn -> 2.0 end)
    expect(SysCallGlue, :get_current_z, 2, fn -> 3.0 end)

    expect(SysCallGlue, :move_absolute, 2, fn
      0, 2.0, 3.0, 100 -> :ok
      1.0, 0, 3.0, 100 -> {:error, "expected stub error"}
    end)

    msg = "expected stub error"
    lua = "return"
    assert {[true], ^lua} = Firmware.go_to_home(["x", 100], lua)
    assert {[nil, ^msg], ^lua} = Firmware.go_to_home(["y", 100], lua)
  end

  test "toggle_pin" do
    expect(SysCallGlue, :toggle_pin, 1, fn
      13 -> :ok
      12 -> {:error, "error"}
    end)

    lua = "return"
    msg = "CeleryScript syscall stubbed: toggle_pin\n"
    assert {[], ^lua} = Firmware.toggle_pin([13], lua)
    assert {[nil, ^msg], ^lua} = Firmware.toggle_pin([12], lua)
  end
end
