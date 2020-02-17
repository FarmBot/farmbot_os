defmodule FarmbotOS.SysCalls.SetPinIOModeTest do
  use ExUnit.Case, async: true
  use Mimic

  setup :verify_on_exit!

  alias FarmbotOS.SysCalls.SetPinIOMode

  test "set_pin_io_mode" do
    modes = %{
      1 => 0x2,
      2 => 0x0,
      3 => 0x1,
      4 => 0x0,
      5 => 0x1,
      6 => 0x2
    }

    expect(FarmbotFirmware, :command, 6, fn
      {:pin_mode_write, [p: pin_number, m: actual_mode]} ->
        expected_mode = Map.fetch!(modes, pin_number)
        assert expected_mode == actual_mode
        :ok
    end)

    SetPinIOMode.set_pin_io_mode(1, "input_pullup")
    SetPinIOMode.set_pin_io_mode(2, "input")
    SetPinIOMode.set_pin_io_mode(3, "output")
    SetPinIOMode.set_pin_io_mode(4, 0x0)
    SetPinIOMode.set_pin_io_mode(5, 0x1)
    SetPinIOMode.set_pin_io_mode(6, 0x2)
  end
end
