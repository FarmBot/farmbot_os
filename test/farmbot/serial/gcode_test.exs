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
end
