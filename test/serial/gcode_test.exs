defmodule Farmbot.Serial.Gcode.ParserTest do
  use ExUnit.Case, async: true

  test "Parses report paramater" do
    a = Farmbot.Serial.Gcode.Parser.parse_code("R21 P0 V0")
    b = Farmbot.Serial.Gcode.Parser.parse_code("R21 P0 V0 Q5")
    assert(a == {:report_parameter_value, :param_version, 0, "0"})
    assert(b == {:report_parameter_value, :param_version, 0, "5"})
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
    assert a == {:report_status_value, 0, 45, "10"}

    b = Farmbot.Serial.Gcode.Parser.parse_code("R41 P40 V4")
    assert b == {:report_pin_value, 40, 4, "0"}
  end

  test "parses end stops" do
    a = Farmbot.Serial.Gcode.Parser.parse_code("R81 XA1 XB1 YA1 YB1 ZA1 ZB1 Q10")
    assert a == {:reporting_end_stops, 1, 1, 1, 1, 1, 1, "10"}

    b = Farmbot.Serial.Gcode.Parser.parse_code("R81 XA0 XB1 YA1 YB1 ZA1 ZB0")
    assert b == {:reporting_end_stops, 0, 1, 1, 1, 1, 0, "0"}
  end

  test "parses software version" do
    a = Farmbot.Serial.Gcode.Parser.parse_code("R83 version string")
    assert a == {:report_software_version, "version string"}

    b = Farmbot.Serial.Gcode.Parser.parse_code("R83")
    assert b == {:report_software_version, -1}
  end

  test "doesnt parse unhandled codes" do
    a = Farmbot.Serial.Gcode.Parser.parse_code("B100")
    assert a == {:unhandled_gcode, "B100"}
  end

  test "parses report position" do
    a = Farmbot.Serial.Gcode.Parser.parse_code("R82 X1 Y2 Z3 Q10")
    assert a == {:report_current_position, 1,2,3,"10"}

    b = Farmbot.Serial.Gcode.Parser.parse_code("R82 X7 Y2 Z3")
    assert b == {:report_current_position, 7,2,3,"0"}
  end
end
