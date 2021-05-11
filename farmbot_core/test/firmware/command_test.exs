defmodule FarmbotCore.Firmware.CommandTest do
  require Helpers
  use ExUnit.Case
  alias FarmbotCore.Firmware.{Command, UARTCore}
  use Mimic
  setup :verify_on_exit!

  def simple_case(title, expected_gcode, t) do
    expect(UARTCore, :start_job, 1, fn gcode ->
      actual = inspect(gcode)

      assert gcode == expected_gcode,
             "Simple test case #{title} failed: #{actual}"
    end)

    assert t.() == true
  end

  test "move_abs/1" do
    simple_case(
      "move_abs/1",
      "G00 X1.00 Y2.00 Z3.00 A32.00 B40.00 C60.00",
      fn -> Command.move_abs(%{x: 1, y: 2.0, z: 3, a: 4.0, b: 5, c: 6.0}) end
    )
  end

  test "go_home()" do
    simple_case("go_home()", "G28", fn -> Command.go_home() end)
  end

  test "go_home(\"x\")" do
    simple_case("go_home(\"x\")", "F84 X1 Y0 Z0", fn -> Command.go_home("x") end)
  end

  test "go_home(\"y\")" do
    simple_case("go_home(\"y\")", "F84 X0 Y1 Z0", fn -> Command.go_home("y") end)
  end

  test "go_home(\"z\")" do
    simple_case("go_home(\"z\")", "F84 X0 Y0 Z1", fn -> Command.go_home("z") end)
  end

  test "find_home(:x)" do
    simple_case("find_home(:x)", "F11", fn -> Command.find_home(:x) end)
  end

  test "find_home(:y)" do
    simple_case("find_home(:y)", "F12", fn -> Command.find_home(:y) end)
  end

  test "find_home(:z)" do
    simple_case("find_home(:z)", "F13", fn -> Command.find_home(:z) end)
  end

  test "find_length(:x)" do
    simple_case("find_length(:x)", "F14", fn -> Command.find_length(:x) end)
  end

  test "find_length(:y)" do
    simple_case("find_length(:y)", "F15", fn -> Command.find_length(:y) end)
  end

  test "find_length(:z)" do
    simple_case("find_length(:z)", "F16", fn -> Command.find_length(:z) end)
  end

  test "read_params()" do
    simple_case("read_params()", "F20", fn -> Command.read_params() end)
  end

  test "read_param(param)" do
    t = fn -> Command.read_param(2) end
    simple_case("read_param(param)", "F21 P2.00", t)
  end

  test "write_param(param, val)" do
    t = fn -> Command.write_param(4, 1.0) end
    simple_case("write_param(param, val)", "F22 P4.00 V1.00", t)
  end

  # test "report_end_stops()" do
  #   simple_case(
  #     "report_end_stops()",
  #     "report_end_stops()",
  #     fn -> Command.report_end_stops() end
  #   )
  # end

  # test "report_software_version()" do
  #   simple_case(
  #     "report_software_version()",
  #     "report_software_version()",
  #     fn -> Command.report_software_version() end
  #   )
  # end

  # test "set_zero(:x)" do
  #   simple_case(
  #     "set_zero(:x)",
  #     "set_zero(:x)",
  #     fn -> Command.set_zer(:) end
  #   )
  # end

  # test "set_zero(:y)" do
  #   simple_case(
  #     "set_zero(:y)",
  #     "set_zero(:y)",
  #     fn -> Command.set_zer(:) end
  #   )
  # end

  # test "set_zero(:z)" do
  #   simple_case(
  #     "set_zero(:z)",
  #     "set_zero(:z)",
  #     fn -> Command.set_zer(:) end
  #   )
  # end

  # test "f22({param, val})" do
  #   simple_case(
  #     "f22({param, val})",
  #     "f22({param, val})",
  #     fn -> Command.f22({param,val) end
  #   )
  # end

  # test "lock()" do
  #   simple_case("lock()", "lock()", fn -> Command.lock() end )
  # end

  # test "unlock()" do
  #   simple_case(
  #     "unlock()",
  #     "unlock()",
  #     fn -> Command.unlock() end
  #   )
  # end
end
