ExUnit.start

defmodule Farmbot.Serial.Gcode.ParserTest do
  use ExUnit.Case, async: true

  test "Parses report paramater" do
    a = Farmbot.Serial.Gcode.Parser.parse_code("R21 P0 V0")
    b = Farmbot.Serial.Gcode.Parser.parse_code("R21 P0 V0 Q5")
    assert(a == {:report_parameter_value, :param_version, 0, "0"})
    assert(b == {:report_parameter_value, :param_version, 0, "5"})
  end
end
