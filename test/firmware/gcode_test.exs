defmodule FarmbotOS.Firmware.GCodeTest do
  use ExUnit.Case
  alias FarmbotOS.Firmware.GCode

  test "bad input" do
    e = fn -> GCode.new(:G00, M: "wrong") end

    m =
      "Expect pin mode to be one of [:analog, :digital, :input, :input_pullup, :output]. Got: \"wrong\""

    assert_raise RuntimeError, m, e
  end
end
