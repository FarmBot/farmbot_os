defmodule FarmbotCore.Firmware.InboundSideEffectsTest do
  use ExUnit.Case
  use Mimic
  import ExUnit.CaptureLog
  alias FarmbotCore.Firmware.InboundSideEffects

  @fake_state %FarmbotCore.Firmware.UARTCore{}

  test "Firmware debug logs" do
    msg = "Hello, world!"
    gcode = [{:debug_message, msg}]
    run = fn -> InboundSideEffects.process(@fake_state, gcode) end
    assert capture_log(run) =~ msg
  end

  test "Debug logging enabled" do
    s = %{@fake_state | logs_enabled: true}
    gcode = {:complete_homing_x, nil}
    run = fn -> InboundSideEffects.process(s, [gcode]) end
    assert capture_log(run) =~ inspect(gcode)
  end

  test "complete_homing_x|y|z" do
    gcode = [
      {:complete_homing_x, nil},
      {:complete_homing_y, nil},
      {:complete_homing_z, nil}
    ]

    results = InboundSideEffects.process(@fake_state, gcode)
    assert results == @fake_state
  end

  test ":axis_state_report" do
    expect(FarmbotCore.BotState, :set_axis_state, fn _axis, _value -> :ok end)

    gcode = [{:axis_state_report, %{x: 2.0}}]
    results = InboundSideEffects.process(@fake_state, gcode)
    assert results == @fake_state
  end

  test ":idle" do
    expect(FarmbotCore.FirmwareEstopTimer, :cancel_timer, 1, fn ->
      :ok
    end)

    expect(FarmbotCore.BotState, :set_firmware_unlocked, 1, fn ->
      :ok
    end)

    expect(FarmbotCore.Firmware.TxBuffer, :process_next_message, 1, fn _, _ ->
      @fake_state.tx_buffer
    end)

    expect(FarmbotCore.BotState, :set_firmware_idle, 1, fn value ->
      assert value
      :ok
    end)

    expect(FarmbotCore.BotState, :set_firmware_busy, 1, fn value ->
      refute value
      :ok
    end)

    expect(FarmbotCore.BotState, :set_axis_state, 3, fn
      :x, value ->
        assert value == "idle"
        :ok

      :y, value ->
        assert value == "idle"
        :ok

      :z, value ->
        assert value == "idle"
        :ok

      _, _ ->
        raise "FAIL"
    end)

    gcode = [{:idle, %{}}]

    results = InboundSideEffects.process(@fake_state, gcode)
    assert results == @fake_state
  end
end
