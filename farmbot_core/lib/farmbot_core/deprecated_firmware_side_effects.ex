defmodule FarmbotCore.DeprecatedFirmwareSideEffects do
  require Logger
  require FarmbotCore.Logger
  alias FarmbotCore.{Asset, BotState, FirmwareEstopTimer, Leds}

  def handle_position(x: x, y: y, z: z) do
    :ok = BotState.set_position(x, y, z)
  end

  def handle_load([_u, x, _v, y, _w, z]) do
    :ok = BotState.set_load(x, y, z)
  end

  def handle_position_change([{axis, 0.0}]) do
    FarmbotCore.Logger.warn(1, "#{axis}-axis stopped at home")
    :noop
  end

  def handle_position_change([{axis, _}]) do
    FarmbotCore.Logger.warn(1, "#{axis}-axis stopped at maximum")
    :noop
  end

  def handle_axis_state([{axis, state}]) do
    BotState.set_axis_state(axis, state)
  end

  def handle_axis_timeout(axis) do
    FarmbotCore.Logger.error(1, "#{axis}-axis timed out waiting for movement to complete")
    :noop
  end

  def handle_home_complete(_) do
    :noop
  end

  def handle_calibration_state([{_axis, _state}]) do
    :noop
  end

  def handle_encoders_scaled(x: x, y: y, z: z) do
    :ok = BotState.set_encoders_scaled(x, y, z)
  end

  # this is a bug in the firmware code i think
  def handle_encoders_scaled([]), do: :noop

  def handle_encoders_raw(x: x, y: y, z: z) do
    :ok = BotState.set_encoders_raw(x, y, z)
  end

  def handle_parameter_value([{param, value}]) do
    :ok = BotState.set_firmware_config(param, value)
  end

  def handle_parameter_calibration_value([{_, 0}]), do: :ok
  def handle_parameter_calibration_value([{_, 0.0}]), do: :ok
  def handle_parameter_calibration_value([{param, value}]) do
    FarmbotCeleryScript.SysCalls.sync()
    Process.sleep(1000)
    %{param => value}
    |> Asset.update_firmware_config!()
    |> Asset.Private.mark_dirty!(%{})
    :ok
  end

  def handle_pin_value(p: pin, v: value) do
    :ok = BotState.set_pin_value(pin, value)
  end

  def handle_software_version([version]) do
    :ok = BotState.set_firmware_version(version)

    case String.split(version, ".") do
      # Ramps
      [_, _, _, "R"] ->
        _ = Leds.red(:solid)
        :ok = BotState.set_firmware_hardware("arduino")
      [_, _, _, "R", _] ->
        _ = Leds.red(:solid)
        :ok = BotState.set_firmware_hardware("arduino")

      # Farmduino
      [_, _, _, "F"] ->
        _ = Leds.red(:solid)
        :ok = BotState.set_firmware_hardware("farmduino")
      [_, _, _, "F", _] ->
        _ = Leds.red(:solid)
        :ok = BotState.set_firmware_hardware("farmduino")

      # Farmduino V14
      [_, _, _, "G"] ->
        _ = Leds.red(:solid)
        :ok = BotState.set_firmware_hardware("farmduino_k14")
      [_, _, _, "G", _] ->
        _ = Leds.red(:solid)
        :ok = BotState.set_firmware_hardware("farmduino_k14")

      # Farmduino V15
      [_, _, _, "H"] ->
        _ = Leds.red(:solid)
        :ok = BotState.set_firmware_hardware("farmduino_k15")
      [_, _, _, "H", _] ->
        _ = Leds.red(:solid)
        :ok = BotState.set_firmware_hardware("farmduino_k15")

      # Express V10
      [_, _, _, "E"] ->
        _ = Leds.red(:solid)
        :ok = BotState.set_firmware_hardware("express_k10")
      [_, _, _, "E", _] ->
        _ = Leds.red(:solid)
        :ok = BotState.set_firmware_hardware("express_k10")

      [_, _, _, "S"] ->
        _ = Leds.red(:slow_blink)
        :ok = BotState.set_firmware_version("none")
        :ok = BotState.set_firmware_hardware("none")
      [_, _, _, "S", _] ->
        _ = Leds.red(:slow_blink)
        :ok = BotState.set_firmware_version("none")
        :ok = BotState.set_firmware_hardware("none")
    end
  end

  def handle_end_stops(_) do
    :noop
  end

  def handle_busy(busy) do
    :ok = BotState.set_firmware_busy(busy)
  end

  def handle_idle(idle) do
    _ = FirmwareEstopTimer.cancel_timer()
    :ok = BotState.set_firmware_unlocked()
    :ok = BotState.set_firmware_idle(idle)
  end

  def handle_emergency_lock() do
    _ = FirmwareEstopTimer.start_timer()
    _ = Leds.red(:fast_blink)
    _ = Leds.yellow(:slow_blink)
    :ok = BotState.set_firmware_locked()
  end

  def handle_emergency_unlock() do
    _ = FirmwareEstopTimer.cancel_timer()
    _ = Leds.red(:solid)
    _ = Leds.yellow(:off)
    :ok = BotState.set_firmware_unlocked()
  end

  def handle_input_gcode(_) do
    :ok
  end

  def handle_output_gcode(_code) do
    :ok
  end

  def handle_debug_message([_message]) do
    :ok
  end

  def do_send_debug_message(_message_string) do
    # Uncomment this line on dev builds if needed.
    # FarmbotCore.Logger.debug(3, "Firmware debug message: " <> message)
    :ok
  end
end
