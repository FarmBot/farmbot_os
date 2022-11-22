defmodule FarmbotOS.Lua.FirmwareTest do
  alias FarmbotOS.Lua.Firmware
  alias FarmbotOS.Celery.SysCallGlue
  alias FarmbotOS.Firmware.Command
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

    expect(SysCallGlue, :get_current_y, 1, fn -> 2.0 end)
    expect(SysCallGlue, :get_current_z, 1, fn -> 3.0 end)

    expect(SysCallGlue, :move_absolute, 5, fn
      1, _, _, _ -> :ok
      _, _, _, _ -> {:error, msg}
    end)

    expect(FarmbotOS.Lua, :raw_eval, 1, fn _, _ -> {:ok, [:result]} end)

    assert {[true], ^lua} = Firmware.move_absolute([1, 2, 3, 4], lua)
    assert {[nil, ^msg], ^lua} = Firmware.move_absolute([5, 6, 7, 8], lua)
    assert {[true], ^lua} = Firmware.move_absolute([1, 2, 3], lua)
    assert {[nil, ^msg], ^lua} = Firmware.move_absolute([5, 6, 7], lua)
    assert {[:result], ^lua} = Firmware.move_absolute([[{"x", 1}]], lua)
    assert {[true], ^lua} = Firmware.move_absolute([[{"x", 1}], 100], lua)
  end

  test "move" do
    expect(FarmbotOS.Lua, :raw_eval, 1, fn _, _ -> {:ok, [:result]} end)
    result = Firmware.move([], :fake_lua)
    assert result == {[:result], :fake_lua}
  end

  test "find_home/2" do
    msg = "expected stub error"
    lua = "return"

    expect(SysCallGlue, :find_home, 5, fn
      "x" -> :ok
      _ -> {:error, msg}
    end)

    assert {[true], ^lua} = Firmware.find_home(["x"], lua)
    assert {[nil, "expected stub error "], ^lua} = Firmware.find_home([], lua)
    assert {[nil, "expected stub error"], ^lua} = Firmware.find_home(["y"], lua)
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

    msg = "expected stub error"
    lua = "return"

    expect(SysCallGlue, :move_absolute, 3, fn
      0, 0, 0, 100 -> :ok
      0, 2.0, 3.0, 100 -> :ok
      1.0, 0, 3.0, 100 -> {:error, msg}
    end)

    assert {[true], ^lua} = Firmware.go_to_home(["x", 100], lua)
    assert {[nil, ^msg], ^lua} = Firmware.go_to_home(["y", 100], lua)
    assert {[true], ^lua} = Firmware.go_to_home(["all"], lua)
  end

  test "get_position - OK" do
    expect(SysCallGlue, :get_current_x, 2, fn -> 1.0 end)
    expect(SysCallGlue, :get_current_y, 2, fn -> 2.0 end)
    expect(SysCallGlue, :get_current_z, 2, fn -> 3.0 end)
    lua = "return"
    assert {[1.0], ^lua} = Firmware.get_position(["x"], lua)
    assert {[2.0], ^lua} = Firmware.get_position(["y"], lua)
    assert {[3.0], ^lua} = Firmware.get_position(["z"], lua)

    assert {[[{"x", 1.0}, {"y", 2.0}, {"z", 3.0}]], ^lua} =
             Firmware.get_position([], lua)
  end

  test "get_position - KO" do
    expect(SysCallGlue, :get_current_x, 1, fn -> {:error, "error"} end)
    expect(SysCallGlue, :get_current_y, 1, fn -> {:error, "error"} end)
    expect(SysCallGlue, :get_current_z, 1, fn -> {:error, "error"} end)
    lua = "return"
    assert {[nil, "error"], ^lua} = Firmware.get_position(["x"], lua)
    assert {[nil, "error"], ^lua} = Firmware.get_position(["y"], lua)
    assert {[nil, "error"], ^lua} = Firmware.get_position(["z"], lua)
  end

  test "check_position" do
    expect(SysCallGlue, :get_current_x, 1, fn -> 1.0 end)
    expect(SysCallGlue, :get_current_y, 2, fn -> 2.0 end)
    expect(SysCallGlue, :get_current_z, 2, fn -> 3.0 end)
    lua = "return"

    assert {[true], ^lua} =
             Firmware.check_position(
               [[{"x", 1.0}, {"y", 2.0}, {"z", 3.0}], 1],
               lua
             )
  end

  test "read_pin" do
    msg = "expected stub error"
    lua = "return"

    expect(Command, :read_pin, 2, fn
      13, 1 -> {:ok, 1}
      12, 1 -> {:error, msg}
    end)

    assert {[1], ^lua} = Firmware.read_pin([13, "analog"], lua)
    assert {[nil, ^msg], ^lua} = Firmware.read_pin([12, "analog"], lua)
  end

  test "toggle_pin" do
    msg = "expected stub error"
    lua = "return"

    expect(SysCallGlue, :toggle_pin, 2, fn
      13 -> :ok
      12 -> {:error, msg}
    end)

    assert {[], ^lua} = Firmware.toggle_pin([13], lua)
    assert {[nil, ^msg], ^lua} = Firmware.toggle_pin([12], lua)
  end

  test "set_pin_io_mode" do
    msg = "expected stub error"
    lua = "return"

    expect(SysCallGlue, :set_pin_io_mode, 2, fn
      13, "output" -> :ok
      12, "input" -> {:error, msg}
    end)

    assert {[true, nil], ^lua} = Firmware.set_pin_io_mode([13, "output"], lua)

    assert {[false, "{:error, \"expected stub error\"}"], ^lua} =
             Firmware.set_pin_io_mode([12, "input"], lua)

    assert {[
              false,
              "Expected pin mode to be one of: [\"input\", \"input_pullup\", \"output\"]"
            ], ^lua} = Firmware.set_pin_io_mode([12, "nope"], lua)
  end

  test "on / off" do
    msg = "expected stub error"
    lua = "return"

    expect(SysCallGlue, :write_pin, 3, fn
      13, 0, 1 -> :ok
      13, 0, 0 -> :ok
      12, 0, 1 -> {:error, msg}
    end)

    assert {[], ^lua} = Firmware.on([13], lua)
    assert {[], ^lua} = Firmware.off([13], lua)
    assert {["\"expected stub error\""], ^lua} = Firmware.on([12], lua)
  end
end
