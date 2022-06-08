defmodule FarmbotOS.SysCalls.PinControlTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!

  alias FarmbotOS.Asset.{
    BoxLed,
    Peripheral,
    Sensor
  }

  alias FarmbotOS.Firmware.Command

  @digital 0
  @analog 1

  @tag :capture_log
  test "read_pin with %Peripheral{}, pin is 1" do
    expect(Command, :read_pin, 1, fn 13, 0 -> {:ok, 1} end)
    peripheral = %Peripheral{pin: 13, label: "xyz"}
    assert 1 == FarmbotOS.SysCalls.read_pin(peripheral, @digital)
  end

  @tag :capture_log
  test "read_pin with %Peripheral{}, pin is 0" do
    expect(Command, :read_pin, 1, fn 13, 0 -> {:ok, 0} end)
    peripheral = %Peripheral{pin: 13, label: "xyz"}
    assert 0 == FarmbotOS.SysCalls.read_pin(peripheral, @digital)
  end

  @tag :capture_log
  test "read_pin with %Peripheral{}, analog" do
    expect(Command, :read_pin, 1, fn 13, 1 -> {:ok, 0} end)
    peripheral = %Peripheral{pin: 13, label: "xyz"}
    assert 0 == FarmbotOS.SysCalls.read_pin(peripheral, @analog)
  end

  @tag :capture_log
  test "read_pin with %BoxLed{}" do
    reject(Command, :read_pin, 2)
    assert 1 == FarmbotOS.SysCalls.read_pin(%BoxLed{}, @digital)
  end

  @tag :capture_log
  test "read_pin with %Sensor{}" do
    expect(Command, :read_pin, 1, fn 13, 0 -> {:ok, 0} end)
    expect(FarmbotOS.SysCalls, :get_position, 1, fn -> %{x: 0, y: 0, z: 0} end)
    sensor = %Sensor{pin: 13, label: "xyz"}
    assert 0 == FarmbotOS.SysCalls.read_pin(sensor, @digital)
  end

  @tag :capture_log
  test "read_pin with %Sensor{}, analog" do
    expect(Command, :read_pin, 1, fn 13, 1 -> {:ok, 0} end)
    expect(FarmbotOS.SysCalls, :get_position, 1, fn -> %{x: 0, y: 0, z: 0} end)
    sensor = %Sensor{pin: 13, label: "xyz"}
    assert 0 == FarmbotOS.SysCalls.read_pin(sensor, @analog)
  end

  @tag :capture_log
  test "read_pin" do
    expect(Command, :read_pin, 1, fn 13, 0 -> {:ok, 0} end)
    assert 0 == FarmbotOS.SysCalls.read_pin(13, @digital)
  end

  @tag :capture_log
  test "read_pin, analog" do
    expect(Command, :read_pin, 1, fn 13, 1 -> {:ok, 0} end)
    assert 0 == FarmbotOS.SysCalls.read_pin(13, @analog)
  end

  @tag :capture_log
  test "write_pin with %Peripheral{}, value 0" do
    expect(Command, :write_pin, 1, fn 13, 0, 0 -> {:ok, 0} end)
    expect(FarmbotOS.BotState, :set_pin_value, 1, fn 13, 0.0, 0 -> {:ok} end)
    peripheral = %Peripheral{pin: 13, label: "xyz"}
    assert :ok == FarmbotOS.SysCalls.write_pin(peripheral, @digital, 0)
  end

  @tag :capture_log
  test "write_pin with %Peripheral{}, value 1" do
    expect(Command, :write_pin, 1, fn 13, 1, 0 -> {:ok, 0} end)
    expect(FarmbotOS.BotState, :set_pin_value, 1, fn 13, 1.0, 0 -> {:ok} end)
    peripheral = %Peripheral{pin: 13, label: "xyz"}
    assert :ok == FarmbotOS.SysCalls.write_pin(peripheral, @digital, 1)
  end

  @tag :capture_log
  test "write_pin with %Peripheral{}, analog" do
    expect(Command, :write_pin, 1, fn 13, 1, 1 -> {:ok, 0} end)
    expect(FarmbotOS.BotState, :set_pin_value, 1, fn 13, 1.0, 1 -> {:ok} end)
    peripheral = %Peripheral{pin: 13, label: "xyz"}
    assert :ok == FarmbotOS.SysCalls.write_pin(peripheral, @analog, 1)
  end

  @tag :capture_log
  test "write_pin with %Sensor{}" do
    reject(Command, :write_pin, 3)
    reject(FarmbotOS.BotState, :set_pin_value, 3)
    sensor = %Sensor{pin: 13, label: "xyz"}
    error = {:error, "cannot write Sensor value. Use a Peripheral"}
    assert error == FarmbotOS.SysCalls.write_pin(sensor, @digital, 1)
  end

  @tag :capture_log
  test "write_pin, value 0" do
    expect(Command, :write_pin, 1, fn 13, 0, 0 -> {:ok, 0} end)
    expect(FarmbotOS.BotState, :set_pin_value, 1, fn 13, 0.0, 0 -> {:ok} end)
    assert :ok == FarmbotOS.SysCalls.write_pin(13, @digital, 0)
  end

  @tag :capture_log
  test "write_pin, value 1" do
    expect(Command, :write_pin, 1, fn 13, 1, 0 -> {:ok, 0} end)
    expect(FarmbotOS.BotState, :set_pin_value, 1, fn 13, 1.0, 0 -> {:ok} end)
    assert :ok == FarmbotOS.SysCalls.write_pin(13, @digital, 1)
  end

  @tag :capture_log
  test "write_pin, analog" do
    expect(Command, :write_pin, 1, fn 13, 1, 1 -> {:ok, 0} end)
    expect(FarmbotOS.BotState, :set_pin_value, 1, fn 13, 1.0, 1 -> {:ok} end)
    assert :ok == FarmbotOS.SysCalls.write_pin(13, @analog, 1)
  end

  @tag :capture_log
  test "write_pin with %BoxLed{id: 3}, value 0" do
    reject(Command, :write_pin, 3)
    reject(FarmbotOS.BotState, :set_pin_value, 3)
    expect(FarmbotOS.Leds, :white4, 1, fn :off -> {:ok} end)
    assert :ok == FarmbotOS.SysCalls.write_pin(%BoxLed{id: 3}, @digital, 0)
  end

  @tag :capture_log
  test "write_pin with %BoxLed{id: 3}, value 1" do
    reject(Command, :write_pin, 3)
    reject(FarmbotOS.BotState, :set_pin_value, 3)
    expect(FarmbotOS.Leds, :white4, 1, fn :solid -> {:ok} end)
    assert :ok == FarmbotOS.SysCalls.write_pin(%BoxLed{id: 3}, @digital, 1)
  end

  @tag :capture_log
  test "write_pin with %BoxLed{id: 4}, value 0" do
    reject(Command, :write_pin, 3)
    reject(FarmbotOS.BotState, :set_pin_value, 3)
    expect(FarmbotOS.Leds, :white5, 1, fn :off -> {:ok} end)
    assert :ok == FarmbotOS.SysCalls.write_pin(%BoxLed{id: 4}, @digital, 0)
  end

  @tag :capture_log
  test "write_pin with %BoxLed{id: 4}, value 1" do
    reject(Command, :write_pin, 3)
    reject(FarmbotOS.BotState, :set_pin_value, 3)
    expect(FarmbotOS.Leds, :white5, 1, fn :solid -> {:ok} end)
    assert :ok == FarmbotOS.SysCalls.write_pin(%BoxLed{id: 4}, @digital, 1)
  end

  @tag :capture_log
  test "write_pin with %BoxLed{}, analog" do
    reject(Command, :write_pin, 3)
    reject(FarmbotOS.BotState, :set_pin_value, 3)
    reject(FarmbotOS.Leds, :white4, 1)
    error = {:error, "cannot write Boxled3 in analog mode"}
    assert error == FarmbotOS.SysCalls.write_pin(%BoxLed{id: 3}, @analog, 1)
  end

  @tag :capture_log
  test "toggle_pin, 1 => 0" do
    expect(FarmbotOS.Asset, :get_peripheral_by_pin, 1, fn pin ->
      assert pin == 12
      nil
    end)

    expect(Command, :set_pin_io_mode, 1, fn pin, mode ->
      assert pin == 12
      assert mode == :output
      {:ok, nil}
    end)

    expect(Command, :write_pin, 1, fn pin, _, _ ->
      assert pin == 12
      {:ok, nil}
    end)

    expect(Command, :read_pin, 2, fn pin, mode ->
      assert pin == 12
      assert mode == :digital || mode == 0
      {:ok, 1}
    end)

    assert :ok = FarmbotOS.SysCalls.toggle_pin(12)
  end

  @tag :capture_log
  test "toggle_pin, 0 => 1" do
    expect(FarmbotOS.Asset, :get_peripheral_by_pin, 1, fn 12 ->
      nil
    end)

    expect(Command, :write_pin, 1, fn pin, value, _ ->
      assert pin == 12
      assert value == 1
      {:ok, nil}
    end)

    expect(Command, :read_pin, 2, fn pin, mode ->
      assert pin == 12
      assert mode == :digital || mode == 0
      {:ok, 0}
    end)

    expect(Command, :set_pin_io_mode, 1, fn pin, mode ->
      assert pin == 12
      assert mode == :output
      {:ok, nil}
    end)

    assert :ok = FarmbotOS.SysCalls.toggle_pin(12)
  end

  @tag :capture_log
  test "toggle_pin, read_pin error" do
    reject(Command, :write_pin, 3)

    expect(Command, :read_pin, 1, fn pin, mode ->
      assert pin == 13
      assert mode == :digital || mode == 0
      {:error, nil}
    end)

    expect(Command, :set_pin_io_mode, 1, fn pin, mode ->
      assert pin == 13
      assert mode == :output
      {:ok, nil}
    end)

    error = {:error, "Firmware error @ \"toggle_pin\": {:error, nil}"}
    assert error = FarmbotOS.SysCalls.toggle_pin(13)
  end

  @tag :capture_log
  test "toggle_pin, set_pin_io_mode error" do
    reject(Command, :write_pin, 3)

    reject(Command, :read_pin, 2)

    expect(Command, :set_pin_io_mode, 1, fn pin, mode ->
      assert pin == 13
      assert mode == :output
      {:error, nil}
    end)

    error = {:error, "Firmware error @ \"toggle_pin\": {:error, nil}"}
    assert error = FarmbotOS.SysCalls.toggle_pin(13)
  end

  @tag :capture_log
  test "toggle_pin, write_pin error" do
    expect(Command, :write_pin, 1, fn pin, value, _ ->
      assert pin == 13
      assert value == 0
      {:error, nil}
    end)

    expect(Command, :read_pin, 1, fn pin, mode ->
      assert pin == 13
      assert mode == :digital || mode == 0
      {:ok, 1}
    end)

    expect(Command, :set_pin_io_mode, 1, fn pin, mode ->
      assert pin == 13
      assert mode == :output
      {:ok, nil}
    end)

    error = {:error, "Firmware error @ \"toggle_pin\": {:error, nil}"}
    assert error = FarmbotOS.SysCalls.toggle_pin(13)
  end

  @tag :capture_log
  test "toggle_pin with %Peripheral{}, 0 => 1" do
    expect(Command, :write_pin, 1, fn pin, value, _ ->
      assert pin == 13
      assert value == 1
      {:ok, nil}
    end)

    expect(Command, :read_pin, 2, fn pin, mode ->
      assert pin == 13
      assert mode == :digital || mode == 0
      {:ok, 0}
    end)

    expect(Command, :set_pin_io_mode, 1, fn pin, mode ->
      assert pin == 13
      assert mode == :output
      {:ok, nil}
    end)

    peripheral = %Peripheral{pin: 13, label: "xyz"}
    assert :ok = FarmbotOS.SysCalls.toggle_pin(peripheral)
  end

  @tag :capture_log
  test "toggle_pin with %Peripheral{}, 1 => 0" do
    expect(Command, :write_pin, 1, fn pin, value, _ ->
      assert pin == 13
      assert value == 0
      {:ok, nil}
    end)

    expect(Command, :read_pin, 2, fn pin, mode ->
      assert pin == 13
      assert mode == :digital || mode == 0
      {:ok, 1}
    end)

    expect(Command, :set_pin_io_mode, 1, fn pin, mode ->
      assert pin == 13
      assert mode == :output
      {:ok, nil}
    end)

    peripheral = %Peripheral{pin: 13, label: "xyz"}
    assert :ok = FarmbotOS.SysCalls.toggle_pin(peripheral)
  end

  @tag :capture_log
  test "toggle_pin with %Peripheral{}, read_pin error" do
    reject(Command, :write_pin, 3)

    expect(Command, :read_pin, 1, fn pin, mode ->
      assert pin == 13
      assert mode == :digital || mode == 0
      {:error, nil}
    end)

    expect(Command, :set_pin_io_mode, 1, fn pin, mode ->
      assert pin == 13
      assert mode == :output
      {:ok, nil}
    end)

    peripheral = %Peripheral{pin: 13, label: "xyz"}
    error = {:error, "Firmware error @ \"toggle_pin\": {:error, nil}"}
    assert error = FarmbotOS.SysCalls.toggle_pin(peripheral)
  end

  @tag :capture_log
  test "toggle_pin with %Peripheral{}, set_pin_io_mode error" do
    reject(Command, :write_pin, 3)

    reject(Command, :read_pin, 2)

    expect(Command, :set_pin_io_mode, 1, fn pin, mode ->
      assert pin == 13
      assert mode == :output
      {:error, nil}
    end)

    peripheral = %Peripheral{pin: 13, label: "xyz"}
    error = {:error, "Firmware error @ \"toggle_pin\": {:error, nil}"}
    assert error = FarmbotOS.SysCalls.toggle_pin(peripheral)
  end

  @tag :capture_log
  test "toggle_pin with %Peripheral{}, write_pin error" do
    expect(Command, :write_pin, 1, fn pin, value, _ ->
      assert pin == 13
      assert value == 0
      {:error, nil}
    end)

    expect(Command, :read_pin, 1, fn pin, mode ->
      assert pin == 13
      assert mode == :digital || mode == 0
      {:ok, 1}
    end)

    expect(Command, :set_pin_io_mode, 1, fn pin, mode ->
      assert pin == 13
      assert mode == :output
      {:ok, nil}
    end)

    peripheral = %Peripheral{pin: 13, label: "xyz"}
    error = {:error, "Firmware error @ \"toggle_pin\": {:error, nil}"}
    assert error = FarmbotOS.SysCalls.toggle_pin(peripheral)
  end

  test "toggle_pin, box LED" do
    error = {:error, "Cannot toggle box LEDs."}
    assert error == FarmbotOS.SysCalls.toggle_pin(%BoxLed{})
  end

  test "toggle_pin, unknown" do
    assert {:error, "Unknown pin data: :x"} == FarmbotOS.SysCalls.toggle_pin(:x)
  end

  test "set_servo_angle" do
    expect(Command, :move_servo, 2, fn
      20, 90 -> {:error, "opps"}
      40, 180 -> {:ok, nil}
    end)

    assert :ok = FarmbotOS.SysCalls.set_servo_angle(40, 180)

    message = "Firmware error @ \"set_servo_angle\": \"opps\""

    assert {:error, ^message} = FarmbotOS.SysCalls.set_servo_angle(20, 90)
  end

  test "read_cached_pin" do
    expect(FarmbotOS.BotState, :fetch, 1, fn ->
      %FarmbotOS.BotStateNG{pins: %{4 => %{value: 6}}}
    end)

    assert 6 == FarmbotOS.SysCalls.read_cached_pin(4)
  end

  test "read_cached_pin, pin" do
    expect(FarmbotOS.BotState, :fetch, 1, fn ->
      %FarmbotOS.BotStateNG{pins: %{4 => %{value: 6}}}
    end)

    assert 6 == FarmbotOS.SysCalls.read_cached_pin(%Peripheral{pin: 4})
  end
end
