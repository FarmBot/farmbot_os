defmodule FarmbotCore.Firmware.InboundSideEffectsTest do
  use ExUnit.Case
  use Mimic

  import ExUnit.CaptureLog

  alias FarmbotCore.Firmware.InboundSideEffects
  alias FarmbotCore.Asset

  @fake_state %FarmbotCore.Firmware.UARTCore{}

  test "" do
  end

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

  test ":calibration_state_report" do
    expected = %{
      movement_axis_nr_steps_y: 101.0,
      movement_axis_nr_steps_z: 150.0
    }

    expect(Asset, :update_firmware_config!, fn actual ->
      assert expected == actual
      expected
    end)

    expect(Asset.Private, :mark_dirty!, fn value, params ->
      assert params == %{}
      assert value == expected
    end)

    gcode = [{:calibration_state_report, %{x: 50.0, y: 101.0, z: 150.0}}]
    results = InboundSideEffects.process(@fake_state, gcode)
    assert results == @fake_state
  end

  test ":end_stops_report" do
    # This is a noop. Test is here for completeness.
    gcode = [{:end_stops_report, %{z_endstop_a: 0, z_endstop_b: 0}}]
    results = InboundSideEffects.process(@fake_state, gcode)
    assert results == @fake_state
  end

  test ":encoder_position_scaled" do
    expect(FarmbotCore.BotState, :set_encoders_scaled, 1, fn
      1.2, 3.4, 5.6 -> :ok
      _, _, _ -> raise "Unexpected input"
    end)

    gcode = [{:encoder_position_scaled, %{x: 1.2, y: 3.4, z: 5.6}}]
    results = InboundSideEffects.process(@fake_state, gcode)
    assert results == @fake_state
  end

  test ":encoder_position_raw" do
    expect(FarmbotCore.BotState, :set_encoders_raw, 1, fn
      1.2, 3.4, 5.6 -> :ok
      _, _, _ -> raise "Unexpected input"
    end)

    gcode = [{:encoder_position_raw, %{x: 1.2, y: 3.4, z: 5.6}}]
    results = InboundSideEffects.process(@fake_state, gcode)
    assert results == @fake_state
  end

  test ":current_position" do
    expect(FarmbotCore.BotState, :set_position, 1, fn
      1.2, 3.4, 5.6 -> :ok
      _, _, _ -> raise "Unexpected input"
    end)

    gcode = [{:current_position, %{x: 1.2, y: 3.4, z: 5.6}}]
    results = InboundSideEffects.process(@fake_state, gcode)
    assert results == @fake_state
  end

  test ":axis_state_report" do
    expect(FarmbotCore.BotState, :set_axis_state, fn
      :x, "idle" ->
        :ok

      :y, "begin" ->
        :ok

      :z, "accelerate" ->
        :ok

      axis, state ->
        raise "Unexpected state: #{inspect({axis, state})}"
    end)

    gcode = [
      {:axis_state_report, %{x: 0.0}},
      {:axis_state_report, %{y: 1.0}},
      {:axis_state_report, %{z: 2.0}}
    ]

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
