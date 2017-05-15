defmodule Farmbot.Serial.Gcode.ParserTest do
  use ExUnit.Case, async: true

  test "Parses report paramater" do
    bleep = Farmbot.Serial.Gcode.Parser.parse_code("R21 P0 V0 Q5")
    assert(bleep == {"5", {:report_parameter_value, :param_version, 0}})
  end

  test "pareses a param numbered string" do
    a = Farmbot.Serial.Gcode.Parser.parse_param("13")
    assert(a == :movement_timeout_z)
  end

  test "Pareses a param in integer form" do
    a = Farmbot.Serial.Gcode.Parser.parse_param(13)
    assert(a == :movement_timeout_z)
  end

  test "Parses a param in atom form" do
    a = Farmbot.Serial.Gcode.Parser.parse_param(:movement_timeout_z)
    assert(a == 13)
  end

  test "Parses a param in string form" do
    a = Farmbot.Serial.Gcode.Parser.parse_param("movement_timeout_z")
    assert(a == 13)
  end

  test "Parses  R31 and R41" do
    a = Farmbot.Serial.Gcode.Parser.parse_code("R31 P0 V45 Q10")
    assert a == {"10", {:report_status_value, 0, 45}}
  end

  test "parses end stops" do
    a = Farmbot.Serial.Gcode.Parser.parse_code("R81 XA1 XB1 YA1 YB1 ZA1 ZB1 Q10")
    assert a == {"10", {:report_end_stops, 1, 1, 1, 1, 1, 1}}
  end

  test "parses software version" do
    a = Farmbot.Serial.Gcode.Parser.parse_code("R83 version string Q22")
    assert a == {"22", {:report_software_version, "version string"}}
  end

  test "doesnt parse unhandled codes" do
    a = Farmbot.Serial.Gcode.Parser.parse_code("B100")
    assert a == {:unhandled_gcode, "B100"}
  end

  test "parses report position" do
    a = Farmbot.Serial.Gcode.Parser.parse_code("R82 X1 Y2 Z3 Q10")
    assert a == {"10", {:report_current_position, 1,2,3}}
  end
end
