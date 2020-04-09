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
end
