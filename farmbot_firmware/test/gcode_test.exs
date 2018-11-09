defmodule Farmbot.Firmware.GCODETest do
  use ExUnit.Case
  alias Farmbot.Firmware.GCODE
  doctest GCODE

  test "extracts q codes" do
    assert {"0", ["ABC"]} = GCODE.extract_tag(["ABC", "Q0"])

    assert {"123", ["Y00", "H1", "I1", "K9", "L199"]} =
             GCODE.extract_tag(["Y00", "H1", "I1", "K9", "L199", "Q123"])

    assert {"abc", ["J700"]} = GCODE.extract_tag(["J700", "Qabc"])
    assert {nil, ["H100"]} = GCODE.extract_tag(["H100"])
  end

  describe "receive codes" do
    test "idle" do
      assert {nil, {:report_idle, []}} = GCODE.decode("R00")
      assert {"100", {:report_idle, []}} = GCODE.decode("R00 Q100")

      assert "R00" = GCODE.encode({nil, {:report_idle, []}})
      assert "R00 Q100" = GCODE.encode({"100", {:report_idle, []}})
    end

    test "begin" do
      assert {nil, {:report_begin, []}} = GCODE.decode("R01")
      assert {"100", {:report_begin, []}} = GCODE.decode("R01 Q100")

      assert "R01" = GCODE.encode({nil, {:report_begin, []}})
      assert "R01 Q100" = GCODE.encode({"100", {:report_begin, []}})
    end

    test "success" do
      assert {nil, {:report_success, []}} = GCODE.decode("R02")
      assert {"100", {:report_success, []}} = GCODE.decode("R02 Q100")

      assert "R02" = GCODE.encode({nil, {:report_success, []}})
      assert "R02 Q100" = GCODE.encode({"100", {:report_success, []}})
    end

    test "error" do
      assert {nil, {:report_error, []}} = GCODE.decode("R03")
      assert {"100", {:report_error, []}} = GCODE.decode("R03 Q100")

      assert "R03" = GCODE.encode({nil, {:report_error, []}})
      assert "R03 Q100" = GCODE.encode({"100", {:report_error, []}})
    end

    test "busy" do
      assert {nil, {:report_busy, []}} = GCODE.decode("R04")
      assert {"100", {:report_busy, []}} = GCODE.decode("R04 Q100")

      assert "R04" = GCODE.encode({nil, {:report_busy, []}})
      assert "R04 Q100" = GCODE.encode({"100", {:report_busy, []}})
    end

    test "axis state" do
      assert {nil, {:report_axis_state, [x: :idle]}} = GCODE.decode("R05 X0")
      assert {nil, {:report_axis_state, [x: :begin]}} = GCODE.decode("R05 X1")
      assert {nil, {:report_axis_state, [x: :accelerate]}} = GCODE.decode("R05 X2")
      assert {nil, {:report_axis_state, [x: :cruise]}} = GCODE.decode("R05 X3")
      assert {nil, {:report_axis_state, [x: :decelerate]}} = GCODE.decode("R05 X4")
      assert {nil, {:report_axis_state, [x: :stop]}} = GCODE.decode("R05 X5")
      assert {nil, {:report_axis_state, [x: :crawl]}} = GCODE.decode("R05 X6")

      assert {"12", {:report_axis_state, [x: :idle]}} = GCODE.decode("R05 X0 Q12")
      assert {"12", {:report_axis_state, [x: :begin]}} = GCODE.decode("R05 X1 Q12")
      assert {"12", {:report_axis_state, [x: :accelerate]}} = GCODE.decode("R05 X2 Q12")
      assert {"12", {:report_axis_state, [x: :cruise]}} = GCODE.decode("R05 X3 Q12")
      assert {"12", {:report_axis_state, [x: :decelerate]}} = GCODE.decode("R05 X4 Q12")
      assert {"12", {:report_axis_state, [x: :stop]}} = GCODE.decode("R05 X5 Q12")
      assert {"12", {:report_axis_state, [x: :crawl]}} = GCODE.decode("R05 X6 Q12")

      assert "R05 X0" = GCODE.encode({nil, {:report_axis_state, [x: :idle]}})
      assert "R05 X1" = GCODE.encode({nil, {:report_axis_state, [x: :begin]}})
      assert "R05 X2" = GCODE.encode({nil, {:report_axis_state, [x: :accelerate]}})
      assert "R05 X3" = GCODE.encode({nil, {:report_axis_state, [x: :cruise]}})
      assert "R05 X4" = GCODE.encode({nil, {:report_axis_state, [x: :decelerate]}})
      assert "R05 X5" = GCODE.encode({nil, {:report_axis_state, [x: :stop]}})
      assert "R05 X6" = GCODE.encode({nil, {:report_axis_state, [x: :crawl]}})

      assert "R05 X0 Q12" = GCODE.encode({"12", {:report_axis_state, [x: :idle]}})
      assert "R05 X1 Q12" = GCODE.encode({"12", {:report_axis_state, [x: :begin]}})
      assert "R05 X2 Q12" = GCODE.encode({"12", {:report_axis_state, [x: :accelerate]}})
      assert "R05 X3 Q12" = GCODE.encode({"12", {:report_axis_state, [x: :cruise]}})
      assert "R05 X4 Q12" = GCODE.encode({"12", {:report_axis_state, [x: :decelerate]}})
      assert "R05 X5 Q12" = GCODE.encode({"12", {:report_axis_state, [x: :stop]}})
      assert "R05 X6 Q12" = GCODE.encode({"12", {:report_axis_state, [x: :crawl]}})

      assert {nil, {:report_axis_state, [y: :idle]}} = GCODE.decode("R05 Y0")
      assert {nil, {:report_axis_state, [y: :begin]}} = GCODE.decode("R05 Y1")
      assert {nil, {:report_axis_state, [y: :accelerate]}} = GCODE.decode("R05 Y2")
      assert {nil, {:report_axis_state, [y: :cruise]}} = GCODE.decode("R05 Y3")
      assert {nil, {:report_axis_state, [y: :decelerate]}} = GCODE.decode("R05 Y4")
      assert {nil, {:report_axis_state, [y: :stop]}} = GCODE.decode("R05 Y5")
      assert {nil, {:report_axis_state, [y: :crawl]}} = GCODE.decode("R05 Y6")

      assert {"13", {:report_axis_state, [y: :idle]}} = GCODE.decode("R05 Y0 Q13")
      assert {"13", {:report_axis_state, [y: :begin]}} = GCODE.decode("R05 Y1 Q13")
      assert {"13", {:report_axis_state, [y: :accelerate]}} = GCODE.decode("R05 Y2 Q13")
      assert {"13", {:report_axis_state, [y: :cruise]}} = GCODE.decode("R05 Y3 Q13")
      assert {"13", {:report_axis_state, [y: :decelerate]}} = GCODE.decode("R05 Y4 Q13")
      assert {"13", {:report_axis_state, [y: :stop]}} = GCODE.decode("R05 Y5 Q13")
      assert {"13", {:report_axis_state, [y: :crawl]}} = GCODE.decode("R05 Y6 Q13")

      assert "R05 Y0" = GCODE.encode({nil, {:report_axis_state, [y: :idle]}})
      assert "R05 Y1" = GCODE.encode({nil, {:report_axis_state, [y: :begin]}})
      assert "R05 Y2" = GCODE.encode({nil, {:report_axis_state, [y: :accelerate]}})
      assert "R05 Y3" = GCODE.encode({nil, {:report_axis_state, [y: :cruise]}})
      assert "R05 Y4" = GCODE.encode({nil, {:report_axis_state, [y: :decelerate]}})
      assert "R05 Y5" = GCODE.encode({nil, {:report_axis_state, [y: :stop]}})
      assert "R05 Y6" = GCODE.encode({nil, {:report_axis_state, [y: :crawl]}})

      assert "R05 Y0 Q13" = GCODE.encode({"13", {:report_axis_state, [y: :idle]}})
      assert "R05 Y1 Q13" = GCODE.encode({"13", {:report_axis_state, [y: :begin]}})
      assert "R05 Y2 Q13" = GCODE.encode({"13", {:report_axis_state, [y: :accelerate]}})
      assert "R05 Y3 Q13" = GCODE.encode({"13", {:report_axis_state, [y: :cruise]}})
      assert "R05 Y4 Q13" = GCODE.encode({"13", {:report_axis_state, [y: :decelerate]}})
      assert "R05 Y5 Q13" = GCODE.encode({"13", {:report_axis_state, [y: :stop]}})
      assert "R05 Y6 Q13" = GCODE.encode({"13", {:report_axis_state, [y: :crawl]}})

      assert {nil, {:report_axis_state, [z: :idle]}} = GCODE.decode("R05 Z0")
      assert {nil, {:report_axis_state, [z: :begin]}} = GCODE.decode("R05 Z1")
      assert {nil, {:report_axis_state, [z: :accelerate]}} = GCODE.decode("R05 Z2")
      assert {nil, {:report_axis_state, [z: :cruise]}} = GCODE.decode("R05 Z3")
      assert {nil, {:report_axis_state, [z: :decelerate]}} = GCODE.decode("R05 Z4")
      assert {nil, {:report_axis_state, [z: :stop]}} = GCODE.decode("R05 Z5")
      assert {nil, {:report_axis_state, [z: :crawl]}} = GCODE.decode("R05 Z6")

      assert {"14", {:report_axis_state, [z: :idle]}} = GCODE.decode("R05 Z0 Q14")
      assert {"14", {:report_axis_state, [z: :begin]}} = GCODE.decode("R05 Z1 Q14")
      assert {"14", {:report_axis_state, [z: :accelerate]}} = GCODE.decode("R05 Z2 Q14")
      assert {"14", {:report_axis_state, [z: :cruise]}} = GCODE.decode("R05 Z3 Q14")
      assert {"14", {:report_axis_state, [z: :decelerate]}} = GCODE.decode("R05 Z4 Q14")
      assert {"14", {:report_axis_state, [z: :stop]}} = GCODE.decode("R05 Z5 Q14")
      assert {"14", {:report_axis_state, [z: :crawl]}} = GCODE.decode("R05 Z6 Q14")

      assert "R05 Z0" = GCODE.encode({nil, {:report_axis_state, [z: :idle]}})
      assert "R05 Z1" = GCODE.encode({nil, {:report_axis_state, [z: :begin]}})
      assert "R05 Z2" = GCODE.encode({nil, {:report_axis_state, [z: :accelerate]}})
      assert "R05 Z3" = GCODE.encode({nil, {:report_axis_state, [z: :cruise]}})
      assert "R05 Z4" = GCODE.encode({nil, {:report_axis_state, [z: :decelerate]}})
      assert "R05 Z5" = GCODE.encode({nil, {:report_axis_state, [z: :stop]}})
      assert "R05 Z6" = GCODE.encode({nil, {:report_axis_state, [z: :crawl]}})

      assert "R05 Z0 Q14" = GCODE.encode({"14", {:report_axis_state, [z: :idle]}})
      assert "R05 Z1 Q14" = GCODE.encode({"14", {:report_axis_state, [z: :begin]}})
      assert "R05 Z2 Q14" = GCODE.encode({"14", {:report_axis_state, [z: :accelerate]}})
      assert "R05 Z3 Q14" = GCODE.encode({"14", {:report_axis_state, [z: :cruise]}})
      assert "R05 Z4 Q14" = GCODE.encode({"14", {:report_axis_state, [z: :decelerate]}})
      assert "R05 Z5 Q14" = GCODE.encode({"14", {:report_axis_state, [z: :stop]}})
      assert "R05 Z6 Q14" = GCODE.encode({"14", {:report_axis_state, [z: :crawl]}})
    end

    test "calibration" do
      assert {nil, {:report_calibration_state, [x: :idle]}} = GCODE.decode("R06 X0")
      assert {nil, {:report_calibration_state, [x: :home]}} = GCODE.decode("R06 X1")
      assert {nil, {:report_calibration_state, [x: :end]}} = GCODE.decode("R06 X2")

      assert {"1", {:report_calibration_state, [x: :idle]}} = GCODE.decode("R06 X0 Q1")
      assert {"1", {:report_calibration_state, [x: :home]}} = GCODE.decode("R06 X1 Q1")
      assert {"1", {:report_calibration_state, [x: :end]}} = GCODE.decode("R06 X2 Q1")

      assert "R06 X0" = GCODE.encode({nil, {:report_calibration_state, [x: :idle]}})
      assert "R06 X1" = GCODE.encode({nil, {:report_calibration_state, [x: :home]}})
      assert "R06 X2" = GCODE.encode({nil, {:report_calibration_state, [x: :end]}})

      assert "R06 X0 Q1" = GCODE.encode({"1", {:report_calibration_state, [x: :idle]}})
      assert "R06 X1 Q1" = GCODE.encode({"1", {:report_calibration_state, [x: :home]}})
      assert "R06 X2 Q1" = GCODE.encode({"1", {:report_calibration_state, [x: :end]}})

      assert {nil, {:report_calibration_state, [y: :idle]}} = GCODE.decode("R06 Y0")
      assert {nil, {:report_calibration_state, [y: :home]}} = GCODE.decode("R06 Y1")
      assert {nil, {:report_calibration_state, [y: :end]}} = GCODE.decode("R06 Y2")

      assert {"1", {:report_calibration_state, [y: :idle]}} = GCODE.decode("R06 Y0 Q1")
      assert {"1", {:report_calibration_state, [y: :home]}} = GCODE.decode("R06 Y1 Q1")
      assert {"1", {:report_calibration_state, [y: :end]}} = GCODE.decode("R06 Y2 Q1")

      assert "R06 Y0" = GCODE.encode({nil, {:report_calibration_state, [y: :idle]}})
      assert "R06 Y1" = GCODE.encode({nil, {:report_calibration_state, [y: :home]}})
      assert "R06 Y2" = GCODE.encode({nil, {:report_calibration_state, [y: :end]}})

      assert "R06 Y0 Q1" = GCODE.encode({"1", {:report_calibration_state, [y: :idle]}})
      assert "R06 Y1 Q1" = GCODE.encode({"1", {:report_calibration_state, [y: :home]}})
      assert "R06 Y2 Q1" = GCODE.encode({"1", {:report_calibration_state, [y: :end]}})

      assert {nil, {:report_calibration_state, [z: :idle]}} = GCODE.decode("R06 Z0")
      assert {nil, {:report_calibration_state, [z: :home]}} = GCODE.decode("R06 Z1")
      assert {nil, {:report_calibration_state, [z: :end]}} = GCODE.decode("R06 Z2")

      assert {"1", {:report_calibration_state, [z: :idle]}} = GCODE.decode("R06 Z0 Q1")
      assert {"1", {:report_calibration_state, [z: :home]}} = GCODE.decode("R06 Z1 Q1")
      assert {"1", {:report_calibration_state, [z: :end]}} = GCODE.decode("R06 Z2 Q1")

      assert "R06 Z0" = GCODE.encode({nil, {:report_calibration_state, [z: :idle]}})
      assert "R06 Z1" = GCODE.encode({nil, {:report_calibration_state, [z: :home]}})
      assert "R06 Z2" = GCODE.encode({nil, {:report_calibration_state, [z: :end]}})

      assert "R06 Z0 Q1" = GCODE.encode({"1", {:report_calibration_state, [z: :idle]}})
      assert "R06 Z1 Q1" = GCODE.encode({"1", {:report_calibration_state, [z: :home]}})
      assert "R06 Z2 Q1" = GCODE.encode({"1", {:report_calibration_state, [z: :end]}})
    end

    test "retry" do
      assert {nil, {:report_retry, []}} = GCODE.decode("R07")
      assert {"100", {:report_retry, []}} = GCODE.decode("R07 Q100")

      assert "R07" = GCODE.encode({nil, {:report_retry, []}})
      assert "R07 Q100" = GCODE.encode({"100", {:report_retry, []}})
    end

    test "echo" do
      assert {nil, {:report_echo, ["ABC"]}} = GCODE.decode("R08 * ABC *")
      assert "R08 * ABC *" = GCODE.encode({nil, {:report_echo, ["ABC"]}})
    end

    test "invalid" do
      assert {nil, {:report_invalid, []}} = GCODE.decode("R09")
      assert {"50", {:report_invalid, []}} = GCODE.decode("R09 Q50")

      assert "R09" = GCODE.encode({nil, {:report_invalid, []}})
      assert "R09 Q50" = GCODE.encode({"50", {:report_invalid, []}})
    end

    test "home complete" do
      assert {nil, {:report_home_complete, [:x]}} = GCODE.decode("R11")
      assert {"22", {:report_home_complete, [:x]}} = GCODE.decode("R11 Q22")

      assert {nil, {:report_home_complete, [:y]}} = GCODE.decode("R12")
      assert {"22", {:report_home_complete, [:y]}} = GCODE.decode("R12 Q22")

      assert {nil, {:report_home_complete, [:z]}} = GCODE.decode("R13")
      assert {"22", {:report_home_complete, [:z]}} = GCODE.decode("R13 Q22")
    end

    test "position change" do
      assert {nil, {:report_position_change, [{:x, 200.0}]}} = GCODE.decode("R15 X200")
      assert {"33", {:report_position_change, [{:x, 200.0}]}} = GCODE.decode("R15 X200 Q33")

      assert {nil, {:report_position_change, [{:y, 200.0}]}} = GCODE.decode("R16 Y200")
      assert {"33", {:report_position_change, [{:y, 200.0}]}} = GCODE.decode("R17 Y200 Q33")

      assert {nil, {:report_position_change, [{:z, 200.0}]}} = GCODE.decode("R15 Z200")
      assert {"33", {:report_position_change, [{:z, 200.0}]}} = GCODE.decode("R15 Z200 Q33")
    end

    test "paramater report complete" do
      assert {nil, {:report_paramaters_complete, []}} = GCODE.decode("R20")
      assert {"66", {:report_paramaters_complete, []}} = GCODE.decode("R20 Q66")
    end

    test "axis timeout" do
      assert {nil, {:report_axis_timeout, [:x]}} = GCODE.decode("R71")
      assert {"22", {:report_axis_timeout, [:x]}} = GCODE.decode("R71 Q22")

      assert {nil, {:report_axis_timeout, [:y]}} = GCODE.decode("R72")
      assert {"22", {:report_axis_timeout, [:y]}} = GCODE.decode("R72 Q22")

      assert {nil, {:report_axis_timeout, [:z]}} = GCODE.decode("R73")
      assert {"22", {:report_axis_timeout, [:z]}} = GCODE.decode("R73 Q22")
    end

    test "end stops" do
      assert {nil, {:report_end_stops, [xa: 1, xb: 0, ya: 0, yb: 1, za: 1, zb: 0]}} =
               GCODE.decode("R81 XA1 XB0 YA0 YB1 ZA1 ZB0")
    end

    test "position" do
      assert {nil, {:report_position, [{:x, 100.0}, {:y, 200.0}, {:z, 400.0}]}} =
               GCODE.decode("R82 X100 Y200 Z400")

      assert {"1", {:report_position, [{:x, 100.0}, {:y, 200.0}, {:z, 400.0}]}} =
               GCODE.decode("R82 X100 Y200 Z400 Q1")

      assert {nil, {:report_position, [{:x, 100.0}, {:z, 12.0}]}} = GCODE.decode("R82 X100 Z12")
      assert {nil, {:report_position, [{:z, 5.0}]}} = GCODE.decode("R82 Z5")
    end

    test "version" do
      assert {nil, {:report_software_version, ["6.5.0.G"]}} = GCODE.decode("R83 6.5.0.G")
      assert {"900", {:report_software_version, ["6.5.0.G"]}} = GCODE.decode("R83 6.5.0.G Q900")

      assert "R83 6.5.0.G" = GCODE.encode({nil, {:report_software_version, ["6.5.0.G"]}})
      assert "R83 6.5.0.G Q900" = GCODE.encode({"900", {:report_software_version, ["6.5.0.G"]}})
    end

    test "encoders" do
      assert {nil, {:report_encoders_scaled, [{:x, 100.0}, {:y, 200.0}, {:z, 400.0}]}} =
               GCODE.decode("R84 X100 Y200 Z400")

      assert {"1", {:report_encoders_scaled, [{:x, 100.0}, {:y, 200.0}, {:z, 400.0}]}} =
               GCODE.decode("R84 X100 Y200 Z400 Q1")

      assert {nil, {:report_encoders_raw, [{:x, 100.0}, {:y, 200.0}, {:z, 400.0}]}} =
               GCODE.decode("R85 X100 Y200 Z400")

      assert {"1", {:report_encoders_raw, [{:x, 100.0}, {:y, 200.0}, {:z, 400.0}]}} =
               GCODE.decode("R85 X100 Y200 Z400 Q1")
    end

    test "emergency lock" do
      assert {nil, {:report_emergency_lock, []}} = GCODE.decode("R87")
      assert {"999", {:report_emergency_lock, []}} = GCODE.decode("R87 Q999")

      assert "R87" = GCODE.encode({nil, {:report_emergency_lock, []}})
      assert "R87 Q999" = GCODE.encode({"999", {:report_emergency_lock, []}})
    end

    test "debug message" do
      assert {nil, {:report_debug_message, ["Hello, World!"]}} = GCODE.decode("R99 Hello, World!")
      assert "R99 Hello, World!" = GCODE.encode({nil, {:report_debug_message, ["Hello, World!"]}})
    end
  end
end
