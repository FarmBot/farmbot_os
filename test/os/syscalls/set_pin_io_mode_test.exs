defmodule FarmbotOS.SysCalls.SetPinIOModeTest do
  use ExUnit.Case
  use Mimic

  setup :verify_on_exit!

  alias FarmbotOS.SysCalls.SetPinIOMode
  alias FarmbotOS.Firmware.Command

  test "set_pin_io_mode error handler" do
    real_reason = {:error, "a unit test"}

    expect(Command, :set_pin_io_mode, 1, fn pin, mode ->
      assert pin == 3
      assert mode == 1
      real_reason
    end)

    expect(FarmbotOS.SysCalls, :give_firmware_reason, fn label, reason ->
      assert label == "set_pin_io_mode"
      assert reason == real_reason
    end)

    SetPinIOMode.set_pin_io_mode(3, "output")
  end

  test "set_pin_io_mode" do
    modes = %{
      1 => 0x2,
      2 => 0x0,
      3 => 0x1,
      4 => 0x0,
      5 => 0x1,
      6 => 0x2
    }

    expect(Command, :set_pin_io_mode, 6, fn pin_number, actual_mode ->
      expected_mode = Map.fetch!(modes, pin_number)
      assert expected_mode == actual_mode
      :ok
    end)

    FarmbotOS.SysCalls.set_pin_io_mode(1, "input_pullup")
    FarmbotOS.SysCalls.set_pin_io_mode(2, "input")
    FarmbotOS.SysCalls.set_pin_io_mode(3, "output")
    FarmbotOS.SysCalls.set_pin_io_mode(4, 0x0)
    FarmbotOS.SysCalls.set_pin_io_mode(5, 0x1)
    FarmbotOS.SysCalls.set_pin_io_mode(6, 0x2)
  end
end
