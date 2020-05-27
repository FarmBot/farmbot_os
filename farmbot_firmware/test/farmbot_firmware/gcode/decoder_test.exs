defmodule FarmbotFirmware.GCODE.DecoderTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotFirmware.GCODE.Decoder

  test "Decoder.decode_ints(pvm, acc \\ [])" do
    assert [a: 1, b: 2, c: 3] == Decoder.decode_ints(["A1", "B2", "C3"])
  end

  test "Decoder.decode_pv" do
    assert [param_config_ok: 3.0] == Decoder.decode_pv(["P2", "V3"])
  end

  test "Decoder.decode_uxvywz" do
    assert [1, 2, 3, 4, 5, 6] ==
             Decoder.decode_uxvywz(["U1", "X2", "V3", "Y4", "W5", "Z6"])
  end

  # NOTE: Theese values are totally random and may
  # not represent real-world use of the GCode.
  test "Decoder.decode_floats" do
    assert {:command_movement, []} == Decoder.do_decode("G00", ["XA0.0"])
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
    assert {:report_position, []} == Decoder.do_decode("R82", ["ZB1"])
  end
end
