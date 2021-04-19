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

  def handle_axis_state([{axis, state}]) do
    BotState.set_axis_state(axis, state)
  end

  def handle_axis_timeout(axis) do
    FarmbotCore.Logger.error(1, "#{axis}-axis timed out waiting for movement to complete")
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
end
