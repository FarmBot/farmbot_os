defmodule FarmbotFirmware.GCODE.EncoderTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotFirmware.GCODE.Encoder

  test "Encoder.encode_uxvywz" do
    assert "U1 X2 V3 Y4 W5 Z6" ==
             Encoder.encode_uxvywz([1, 2, 3, 4, 5, 6])
  end
end
