defmodule FarmbotOS.Firmware.CommandTest do
  require Helpers
  use ExUnit.Case
  use Mimic
  alias FarmbotOS.Firmware.{Command, UARTCore}
  alias FarmbotOS.BotState

  setup :verify_on_exit!

  def simple_case(title, expected_gcode, t) do
    expect(UARTCore, :start_job, 1, fn gcode ->
      actual = gcode.string

      message =
        "Simple test case #{title} failed. " <>
          "Expected #{inspect(expected_gcode)}, got #{inspect(actual)}"

      assert actual == expected_gcode, message
    end)

    assert t.() == true
  end

  test "abort" do
    expect(UARTCore, :send_raw, 1, fn
      "@" -> :ok
      "F09" -> raise "NO"
      e -> raise "Unexpected: #{inspect(e)}"
    end)

    assert :ok == Command.abort()
  end

  test "lock / unlock" do
    expect(UARTCore, :send_raw, 2, fn
      "E" -> :ok
      "F09" -> :ok
      e -> raise "Unexpected: #{inspect(e)}"
    end)

    Command.lock()
    Command.unlock()
  end

  test "read_pin/2" do
    expect(UARTCore, :start_job, 1, fn gcode ->
      assert "F42 P13.00 M0.00" == gcode.string
      {:ok, :not_really_used_just_stubbed}
    end)

    expect(FarmbotOS.BotState, :fetch, 1, fn ->
      %{pins: %{13 => %{value: 1.0}}}
    end)

    assert {:ok, 1} == Command.read_pin(13.0, "digital")
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

  def stub_position!() do
    expect(BotState, :fetch, 1, fn ->
      %{location_data: %{position: %{x: 1.0, y: 2.0, z: 3.0}}}
    end)
  end

  test "go_home(\"x\")" do
    stub_position!()
    gcode = "G00 X0.00 Y2.00 Z3.00 A800.00 B800.00 C1000.00"

    simple_case("go_home(\"x\")", gcode, fn ->
      Command.go_home("x")
    end)
  end

  test "go_home(\"y\")" do
    stub_position!()
    gcode = "G00 X1.00 Y0.00 Z3.00 A800.00 B800.00 C1000.00"

    simple_case("go_home(\"y\")", gcode, fn ->
      Command.go_home("y")
    end)
  end

  test "go_home(\"z\")" do
    stub_position!()
    gcode = "G00 X1.00 Y2.00 Z0.00 A800.00 B800.00 C1000.00"

    simple_case("go_home(\"z\")", gcode, fn ->
      Command.go_home("z")
    end)
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

  test "set_zero(:x)" do
    simple_case("set_zero(:x)", "F84 X1.00 Y0.00 Z0.00", fn ->
      Command.set_zero(:x)
    end)
  end

  test "set_zero(:y)" do
    simple_case("set_zero(:y)", "F84 X0.00 Y1.00 Z0.00", fn ->
      Command.set_zero(:y)
    end)
  end

  test "set_zero(:z)" do
    simple_case("set_zero(:z)", "F84 X0.00 Y0.00 Z1.00", fn ->
      Command.set_zero(:z)
    end)
  end

  test "move_servo(pin, angle)" do
    simple_case("move_servo(pin, angle)", "F61 P13.00 V179.00", fn ->
      Command.move_servo(13, 179)
    end)
  end

  test "write_pin(pin, value, mode)" do
    simple_case("write_pin(pin, value, mode)", "F41 P3.00 V2.10 M0.00", fn ->
      Command.write_pin(3, 2.1, 0)
    end)
  end

  test "set_pin_io_mode(pin, mode)" do
    simple_case("set_pin_io_mode(pin, mode)", "F43 P3.00 M0.00", fn ->
      Command.set_pin_io_mode(3, 0)
    end)
  end
end
