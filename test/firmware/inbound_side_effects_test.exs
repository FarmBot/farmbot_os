defmodule FarmbotOS.Firmware.InboundSideEffectsTest do
  use ExUnit.Case
  use Mimic

  import ExUnit.CaptureLog

  alias FarmbotOS.Firmware.InboundSideEffects
  alias FarmbotOS.Asset

  require Helpers

  @fake_state %FarmbotOS.Firmware.UARTCore{}
  @relevant_keys [
    :logs_enabled,
    :needs_config,
    :rx_buffer,
    :tx_buffer,
    :uart_path,
    :uart_pid
  ]

  def simple_case(gcode_array) do
    results = InboundSideEffects.process(@fake_state, gcode_array)
    l = Map.take(results, @relevant_keys)
    r = Map.take(@fake_state, @relevant_keys)
    assert l == r
  end

  test "(x|y|z)_axis_timeout" do
    mapper = fn {gcode, _axis} -> simple_case([{gcode, %{}}]) end

    tests = [
      {:x_axis_timeout, "x"},
      {:y_axis_timeout, "y"},
      {:z_axis_timeout, "z"}
    ]

    Enum.map(tests, mapper)
  end

  test "unknown messages" do
    Helpers.expect_log("Unhandled inbound side effects: {:bleh, %{}}")
    simple_case([{:bleh, %{}}])
  end

  test ":motor_load_report" do
    params = %{x: 7.8, y: 9.0, z: 1.2}

    expect(FarmbotOS.BotState, :set_load, 1, fn x, y, z ->
      assert params.x == x
      assert params.y == y
      assert params.z == z
      :ok
    end)

    simple_case([{:motor_load_report, params}])
  end

  test ":movement_retry" do
    Helpers.expect_log("Retrying movement")
    simple_case([{:movement_retry, %{}}])
  end

  test ":not_configured" do
    gcode = [{:not_configured, %{}}]
    state = @fake_state

    expect(FarmbotOS.BotState, :set_firmware_idle, 1, fn value ->
      refute value
      :ok
    end)

    expect(FarmbotOS.BotState, :set_firmware_busy, 1, fn value ->
      assert value
      :ok
    end)

    results = InboundSideEffects.process(state, gcode)
    l = Map.take(results, @relevant_keys)
    r = Map.take(@fake_state, @relevant_keys)
    assert l == r
  end

  test ":report_updated_param_during_calibration" do
    param = %{pin_or_param: 11.0, value1: 200.0}
    gcode = [{:report_updated_param_during_calibration, param}]
    expected = %{movement_timeout_x: 200.0}

    expect(Asset, :update_firmware_config!, fn actual ->
      assert expected == actual
      expected
    end)

    expect(Asset.Private, :mark_dirty!, fn value, params ->
      assert params == %{}
      assert value == expected
      expected
    end)

    simple_case(gcode)
  end

  test "different_(x|y|z)_coordinate_than_given" do
    x = fn -> simple_case([{:different_x_coordinate_than_given, %{x: 0.0}}]) end
    y = fn -> simple_case([{:different_y_coordinate_than_given, %{y: 3.4}}]) end
    z = fn -> simple_case([{:different_z_coordinate_than_given, %{z: 5.6}}]) end

    Helpers.expect_logs([
      "Stopping at X home instead of specified destination.",
      "Stopping at Y max instead of specified destination.",
      "Stopping at Z max instead of specified destination."
    ])

    capture_log(x)
    capture_log(y)
    capture_log(z)
  end

  test ":pin_value_report" do
    expect(FarmbotOS.BotState, :set_pin_value, 1, fn p, v, m ->
      assert p == 2.0
      assert v == 4.5
      assert m in [0, nil]
      :ok
    end)

    simple_case([{:pin_value_report, %{pin_or_param: 2.3, value1: 4.5}}])
  end

  test ":abort" do
    Helpers.expect_log("Movement cancelled")
    simple_case([{:abort, %{}}])
  end

  test ":software_version" do
    version = "v0.0.0-unit_test"

    expect(FarmbotOS.BotState, :set_firmware_version, 1, fn v ->
      assert v == version
      :ok
    end)

    simple_case([{:software_version, version}])
  end

  test ":emergency_lock" do
    expect(FarmbotOS.BotState, :set_firmware_locked, 1, fn ->
      :ok
    end)

    simple_case([{:emergency_lock, %{}}])
  end

  test ":param_value_report" do
    expect(FarmbotOS.Firmware.ConfigUploader, :verify_param, 1, fn s, val ->
      assert val == {1.0, 3.4}
      s
    end)

    simple_case([{:param_value_report, %{pin_or_param: 1.2, value1: 3.4}}])
  end

  test ":ok" do
    simple_case([{:ok, %{queue: 1.0}}])
  end

  test ":error" do
    simple_case([{:error, %{queue: 1.0}}])
  end

  test ":invalidation" do
    boom = fn -> simple_case([{:invalidation, %{}}]) end
    msg = "FBOS SENT INVALID GCODE"
    assert_raise RuntimeError, msg, boom
  end

  test ":start" do
    expect(FarmbotOS.BotState, :set_firmware_idle, 1, fn value ->
      refute value
      :ok
    end)

    expect(FarmbotOS.BotState, :set_firmware_busy, 1, fn value ->
      assert value
      :ok
    end)

    simple_case([{:start, %{queue: 9}}])
  end

  test ":echo (unlock device)" do
    expect(FarmbotOS.BotState, :set_firmware_unlocked, 1, fn ->
      :ok
    end)

    simple_case([{:echo, "*F09*"}])
  end

  test ":echo", do: simple_case([{:echo, "*F20*"}])

  test ":running" do
    expect(FarmbotOS.BotState, :set_firmware_idle, 1, fn value ->
      refute value
      :ok
    end)

    expect(FarmbotOS.BotState, :set_firmware_busy, 1, fn value ->
      assert value
      :ok
    end)

    simple_case([{:running, %{}}])
  end

  test "Firmware debug logs" do
    msg = "Hello, world!"
    gcode = [{:debug_message, msg}]
    t = fn -> InboundSideEffects.process(@fake_state, gcode) end
    assert capture_log(t) =~ msg
  end

  test "Debug logging enabled" do
    s = %{@fake_state | logs_enabled: true}
    gcode = {:complete_homing_x, nil}
    t = fn -> InboundSideEffects.process(s, [gcode]) end
    assert capture_log(t) =~ inspect(gcode)
  end

  test "complete_homing_x|y|z" do
    simple_case([
      {:complete_homing_x, nil},
      {:complete_homing_y, nil},
      {:complete_homing_z, nil}
    ])
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
    simple_case(gcode)
  end

  test ":end_stops_report" do
    # This is a noop. Test is here for completeness.
    simple_case([{:end_stops_report, %{z_endstop_a: 0, z_endstop_b: 0}}])
  end

  test ":encoder_position_scaled" do
    expect(FarmbotOS.BotState, :set_encoders_scaled, 1, fn
      1.2, 3.4, 5.6 -> :ok
      _, _, _ -> raise "Unexpected input"
    end)

    simple_case([{:encoder_position_scaled, %{x: 1.2, y: 3.4, z: 5.6}}])
  end

  test ":encoder_position_raw" do
    expect(FarmbotOS.BotState, :set_encoders_raw, 1, fn
      1.2, 3.4, 5.6 -> :ok
      _, _, _ -> raise "Unexpected input"
    end)

    simple_case([{:encoder_position_raw, %{x: 1.2, y: 3.4, z: 5.6}}])
  end

  test ":current_position" do
    expect(FarmbotOS.BotState, :set_position, 1, fn
      1.2, 3.4, 5.6 -> :ok
      _, _, _ -> raise "Unexpected input"
    end)

    simple_case([{:current_position, %{x: 1.2, y: 3.4, z: 5.6}}])
  end

  test ":axis_state_report" do
    expect(FarmbotOS.BotState, :set_axis_state, fn
      :x, "idle" ->
        :ok

      :y, "begin" ->
        :ok

      :z, "accelerate" ->
        :ok

      axis, state ->
        raise "Unexpected state: #{inspect({axis, state})}"
    end)

    simple_case([
      {:axis_state_report, %{x: 0.0}},
      {:axis_state_report, %{y: 1.0}},
      {:axis_state_report, %{z: 2.0}}
    ])
  end

  test ":idle" do
    expect(FarmbotOS.FirmwareEstopTimer, :cancel_timer, 1, fn ->
      :ok
    end)

    expect(FarmbotOS.BotState, :set_firmware_unlocked, 1, fn ->
      :ok
    end)

    expect(FarmbotOS.Firmware.TxBuffer, :process_next_message, 1, fn _, _ ->
      @fake_state.tx_buffer
    end)

    expect(FarmbotOS.BotState, :set_firmware_idle, 1, fn value ->
      assert value
      :ok
    end)

    expect(FarmbotOS.BotState, :set_firmware_busy, 1, fn value ->
      refute value
      :ok
    end)

    expect(FarmbotOS.BotState, :set_axis_state, 3, fn
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

    simple_case([{:idle, %{}}])
  end
end
