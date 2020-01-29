defmodule FarmbotFirmware.GCODE.DecoderTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotFirmware.GCODE.Decoder

  # NOTE: Theese values are totally random and may
  # not represent real-world use of the GCode.
  test "Decoder.decode_floats" do
    assert {:command_movement, []} == Decoder.do_decode("G00", ["XA0.0"])
    assert {:report_load, [x: 0.0]} == Decoder.do_decode("R89", ["X0.0"])
    assert {:report_encoders_raw, [x: 0.0]} == Decoder.do_decode("R85", ["X0"])
    assert {:report_encoders_scaled, []} == Decoder.do_decode("R84", ["XA-0.0"])
    assert {:report_position, []} == Decoder.do_decode("R82", ["XA-0"])
    assert {:report_position_change, []} == Decoder.do_decode("R17", ["XB1.0"])
    assert {:report_position_change, []} == Decoder.do_decode("R16", ["XB-1.0"])
    assert {:report_position_change, []} == Decoder.do_decode("R15", ["XB10"])

    assert {:report_position_change, [x: 1.0]} ==
             Decoder.do_decode("R15", ["X1"])

    assert {:report_position_change, []} == Decoder.do_decode("R16", ["YA1"])
    assert {:command_movement, []} == Decoder.do_decode("G00", ["YB1"])
    assert {:report_load, []} == Decoder.do_decode("R89", ["ZA1"])
    assert {:report_position, []} == Decoder.do_decode("R82", ["ZB1"])
  end
end
