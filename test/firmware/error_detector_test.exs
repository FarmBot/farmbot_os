defmodule FarmbotOS.Firmware.ErrorDetectorTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.Firmware.ErrorDetector

  setup :verify_on_exit!

  test "Flash.run/2" do
    tests = [
      {2, "Movement timed out"},
      {31, "Stall detected on X axis"},
      {32, "Stall detected on Y axis"},
      {33, "Stall detected on Z axis"}
    ]

    Enum.map(tests, fn {code, expected_message} ->
      actual_message = ErrorDetector.detect(code)
      assert expected_message == actual_message
    end)
  end
end
