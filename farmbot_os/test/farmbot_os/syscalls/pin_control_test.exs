defmodule FarmbotOS.SysCalls.PinControlTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotOS.SysCalls.PinControl
  alias FarmbotCore.Asset.Peripheral
  @digital 0

  @tag :capture_log
  test "read_pin with %Peripheral{}, pin is 1" do
    expect(FarmbotCore.Firmware, :request, 1, fn
      {:pin_read, [p: 13, m: 0]} ->
        {:ok, {:qqq, {:report_pin_value, [p: 13, v: 1]}}}
    end)

    peripheral = %Peripheral{
      pin: 13,
      label: "xyz"
    }

    assert 1 == PinControl.read_pin(peripheral, @digital)
  end

  @tag :capture_log
  test "read_pin with %Peripheral{}, pin is 0" do
    expect(FarmbotCore.Firmware, :request, 1, fn
      {:pin_read, [p: 13, m: 0]} ->
        {:ok, {:qqq, {:report_pin_value, [p: 13, v: 0]}}}
    end)

    peripheral = %Peripheral{pin: 13, label: "xyz"}
    assert 0 == PinControl.read_pin(peripheral, @digital)
  end

  @tag :capture_log
  test "toggle_pin, 1 => 0" do
    expect(FarmbotCore.Asset, :get_peripheral_by_pin, 1, fn 12 ->
      nil
    end)

    expect(FarmbotCore.Firmware, :command, 2, fn
      {:pin_mode_write, [p: 12, m: 1]} -> :ok
      {:pin_write, [p: 12, v: _, m: _]} -> :ok
    end)

    expect(FarmbotCore.Firmware, :request, 2, fn
      {:pin_read, [p: 12, m: 0]} ->
        {:ok, {:qqq, {:report_pin_value, [p: 12, v: 1]}}}
    end)

    assert :ok = PinControl.toggle_pin(12)
  end

  @tag :capture_log
  test "toggle_pin, 0 => 1" do
    expect(FarmbotCore.Asset, :get_peripheral_by_pin, 1, fn 12 ->
      nil
    end)

    expect(FarmbotCore.Firmware, :command, 2, fn
      {:pin_mode_write, [p: 12, m: 1]} -> :ok
      {:pin_write, [p: 12, v: _, m: _]} -> :ok
    end)

    expect(FarmbotCore.Firmware, :request, 2, fn
      {:pin_read, [p: 12, m: 0]} ->
        {:ok, {:qqq, {:report_pin_value, [p: 12, v: 0]}}}
    end)

    assert :ok = PinControl.toggle_pin(12)
  end

  test "toggle_pin, unknown" do
    assert {:error, "Unknown pin data: :x"} == PinControl.toggle_pin(:x)
  end

  test "set_servo_angle" do
    expect(FarmbotCore.Firmware, :command, 2, fn
      {:servo_write, [p: 20, v: 90]} -> {:error, "opps"}
      {:servo_write, [p: 40, v: 180]} -> :ok
    end)

    assert :ok = PinControl.set_servo_angle(40, 180)

    message = "Firmware error @ \"set_servo_angle\": \"opps\""

    assert {:error, ^message} = PinControl.set_servo_angle(20, 90)
  end

  test "read_cached_pin" do
    expect(FarmbotCore.BotState, :fetch, 1, fn ->
      %FarmbotCore.BotStateNG{pins: %{4 => %{value: 6}}}
    end)

    assert 6 == PinControl.read_cached_pin(4)
  end
end
