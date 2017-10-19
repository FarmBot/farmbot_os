defmodule Farmbot.Firmware.Gcode.ParserTest do
  use ExUnit.Case, async: true

  test "Parses report paramater" do
    bleep = Farmbot.Firmware.Gcode.Parser.parse_code("R21 P0 V0 Q5")
    assert(bleep == {"5", {:report_parameter_value, :param_version, 0}})
  end

  test "pareses a param numbered string" do
    a = Farmbot.Firmware.Gcode.Parser.parse_param("13")
    assert(a == :movement_timeout_z)
  end

  test "Pareses a param in integer form" do
    a = Farmbot.Firmware.Gcode.Parser.parse_param(13)
    assert(a == :movement_timeout_z)
  end

  test "Parses a param in atom form" do
    a = Farmbot.Firmware.Gcode.Parser.parse_param(:movement_timeout_z)
    assert(a == 13)
  end

  test "Parses a param in string form" do
    a = Farmbot.Firmware.Gcode.Parser.parse_param("movement_timeout_z")
    assert(a == 13)
  end

  test "Parses  R31 and R41" do
    a = Farmbot.Firmware.Gcode.Parser.parse_code("R31 P0 V45 Q10")
    assert a == {"10", {:report_status_value, 0, 45}}
  end

  test "parses end stops" do
    a = Farmbot.Firmware.Gcode.Parser.parse_code("R81 XA1 XB1 YA1 YB1 ZA1 ZB1 Q10")
    assert a == {"10", {:report_end_stops, 1, 1, 1, 1, 1, 1}}
  end

  test "parses software version" do
    a = Farmbot.Firmware.Gcode.Parser.parse_code("R83 version string Q22")
    assert a == {"22", {:report_software_version, "version string"}}
  end

  test "doesnt parse unhandled codes" do
    a = Farmbot.Firmware.Gcode.Parser.parse_code("B100")
    assert a == {:unhandled_gcode, "B100"}
  end

  test "parses report position" do
    a = Farmbot.Firmware.Gcode.Parser.parse_code("R82 X1.0 Y2.0 Z3.0 Q10")
    assert a == {"10", {:report_current_position, 1.0, 2.0, 3.0}}
  end

  test "parses report calibration" do
    a = Farmbot.Firmware.Gcode.Parser.parse_code("R06 X0 Q1")
    assert a == {"1", {:report_calibration, "X", :idle}}

    b = Farmbot.Firmware.Gcode.Parser.parse_code("R06 Y1 Q2")
    assert b == {"2", {:report_calibration, "Y", :home}}

    c = Farmbot.Firmware.Gcode.Parser.parse_code("R06 Z2 Q3")
    assert c == {"3", {:report_calibration, "Z", :end}}
  end

  test "parses report axis calibration" do
    a = Farmbot.Firmware.Gcode.Parser.parse_code("R23 P141 V123 Q1")
    assert a == {"1", {:report_axis_calibration, :movement_axis_nr_steps_x, 123}}

    assert Farmbot.Firmware.Gcode.Parser.parse_code("R23 P122 V123 Q1") == {"1", :noop}
  end

  test "parses report pin value" do
    a = Farmbot.Firmware.Gcode.Parser.parse_code("R41 P13 V1 Q123")
    assert a == {"123", {:report_pin_value, 13, 1}}
  end

  test "parses report encoder position scaled" do
    a = Farmbot.Firmware.Gcode.Parser.parse_code("R84 X1.0 Y2.0 Z3.0 Q123")
    assert a == {"123", {:report_encoder_position_scaled, 1.0, 2.0, 3.0}}
  end

  test "parses report encoder position raw" do
    a = Farmbot.Firmware.Gcode.Parser.parse_code("R85 X1 Y2 Z3 Q123")
    assert a == {"123", {:report_encoder_position_raw, 1, 2, 3}}
  end
end
