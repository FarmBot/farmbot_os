defmodule FarmbotOS.Lua.Ext.FirmwareTest do
  alias FarmbotOS.Lua.Ext.Firmware
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!

  test "calibrate/2" do
    msg = "expected stub error"
    lua = "return"

    expect(FarmbotCeleryScript.SysCalls, :calibrate, 2, fn
      "x" -> :ok
      _ -> {:error, msg}
    end)

    assert {[true], ^lua} = Firmware.calibrate(["x"], lua)
    assert {[nil, ^msg], ^lua} = Firmware.calibrate(["y"], lua)
  end

  test "move_absolute/2" do
    msg = "expected stub error"
    lua = "return"

    expect(FarmbotCeleryScript.SysCalls, :move_absolute, 4, fn
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

    expect(FarmbotCeleryScript.SysCalls, :find_home, 2, fn
      "x" -> :ok
      _ -> {:error, msg}
    end)

    assert {[true], ^lua} = Firmware.find_home(["x"], lua)
    assert {[nil, ^msg], ^lua} = Firmware.find_home(["y"], lua)
  end

  test "emergency_lock/2" do
    msg = "expected stub error"
    lua = "return"

    expect(FarmbotCeleryScript.SysCalls, :emergency_lock, 1, fn -> :ok end)
    assert {[true], ^lua} = Firmware.emergency_lock(:ok, lua)

    expect(FarmbotCeleryScript.SysCalls, :emergency_lock, 1, fn ->
      {:error, msg}
    end)

    assert {[nil, ^msg], ^lua} = Firmware.emergency_lock(nil, lua)
  end

  test "emergency_unlock/2" do
    msg = "expected stub error"
    lua = "return"

    expect(FarmbotCeleryScript.SysCalls, :emergency_unlock, 1, fn -> :ok end)
    assert {[true], ^lua} = Firmware.emergency_unlock(:ok, lua)

    expect(FarmbotCeleryScript.SysCalls, :emergency_unlock, 1, fn ->
      {:error, msg}
    end)

    assert {[nil, ^msg], ^lua} = Firmware.emergency_unlock(nil, lua)
  end

  test "home" do
    msg = "expected stub error"
    lua = "return"

    expect(FarmbotCeleryScript.SysCalls, :home, 2, fn
      "x", _speed -> :ok
      _, _speed -> {:error, msg}
    end)

    assert {[true], ^lua} = Firmware.home(["x", 100], lua)
    assert {[nil, ^msg], ^lua} = Firmware.home(["y", 100], lua)
  end
end
