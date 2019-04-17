defmodule FarmbotCore.FirmwareSideEffects do
  @moduledoc "Handles firmware data and syncing it with BotState."
  @behaviour FarmbotFirmware.SideEffects
  require Logger
  require FarmbotCore.Logger
  alias FarmbotCore.{Asset, BotState}
  alias FarmbotCore.FirmwareEstopTimer

  @impl FarmbotFirmware.SideEffects
  def handle_position(x: x, y: y, z: z) do
    :ok = BotState.set_position(x, y, z)
  end

  @impl FarmbotFirmware.SideEffects
  def handle_position_change([{_axis, _value}]) do
    :noop
  end

  @impl FarmbotFirmware.SideEffects
  def handle_axis_state([{_axis, _state}]) do
    :noop
  end

  @impl FarmbotFirmware.SideEffects
  def handle_calibration_state([{_axis, _state}]) do
    :noop
  end

  @impl FarmbotFirmware.SideEffects
  def handle_encoders_scaled(x: x, y: y, z: z) do
    :ok = BotState.set_encoders_scaled(x, y, z)
  end


  @impl FarmbotFirmware.SideEffects
  def handle_encoders_raw(x: x, y: y, z: z) do
    :ok = BotState.set_encoders_raw(x, y, z)
  end

  @impl FarmbotFirmware.SideEffects
  def handle_parameter_value([{param, value}]) do
    :ok = BotState.set_firmware_config(param, value)
  end

  def handle_parameter_calibration_value([{param, value}]) do
    %{param => value}
    |> Asset.update_firmware_config!()
    |> Asset.Private.mark_dirty!(%{})
    :ok
  end

  @impl FarmbotFirmware.SideEffects
  def handle_pin_value(p: pin, v: value) do
    :ok = BotState.set_pin_value(pin, value)
  end

  @impl FarmbotFirmware.SideEffects
  def handle_software_version([version]) do
    :ok = BotState.set_firmware_version(version)
    case String.split(version, ".") do
      [_, _, _, "R"] ->
        :ok = BotState.set_firmware_hardware("arduino")
      [_, _, _, "F"] ->
        :ok = BotState.set_firmware_hardware("farmduino")
      [_, _, _, "G"] ->
        :ok = BotState.set_firmware_hardware("farmduino_k14")
      [_, _, _, "S"] ->
        :ok = BotState.set_firmware_hardware("stubduino")
    end
  end

  @impl FarmbotFirmware.SideEffects
  def handle_end_stops(_) do
    :noop
  end

  @impl FarmbotFirmware.SideEffects
  def handle_busy(busy) do
    :ok = BotState.set_firmware_busy(busy)
  end


  @impl FarmbotFirmware.SideEffects
  def handle_idle(idle) do
    :ok = BotState.set_firmware_idle(idle)
  end

  @impl FarmbotFirmware.SideEffects
  def handle_emergency_lock() do
    _ = FirmwareEstopTimer.start_timer()
    :ok = BotState.set_firmware_locked()
  end

  @impl FarmbotFirmware.SideEffects
  def handle_emergency_unlock() do
    _ = FirmwareEstopTimer.cancel_timer()
    :ok = BotState.set_firmware_unlocked()
  end

  @impl FarmbotFirmware.SideEffects
  def handle_input_gcode({_, {:unknown, _}}) do
    :ok
  end

  def handle_input_gcode({:unknown, _}) do
    :ok
  end

  def handle_input_gcode(code) do
    string_code = FarmbotFirmware.GCODE.encode(code)
    should_log? = Asset.fbos_config().firmware_input_log
    should_log? && FarmbotCore.Logger.debug(3, "Firmware input: " <> string_code)
    # IO.inspect(string_code, label: "input")
  end

  @impl FarmbotFirmware.SideEffects
  def handle_output_gcode(code) do
    string_code = FarmbotFirmware.GCODE.encode(code)
    should_log? = Asset.fbos_config().firmware_output_log
    should_log? && FarmbotCore.Logger.debug(3, "Firmware output: " <> string_code)
    # IO.inspect(string_code, label: "output")
  end

  @impl FarmbotFirmware.SideEffects
  def handle_debug_message([message]) do
    should_log? = Asset.fbos_config().firmware_debug_log
    should_log? && FarmbotCore.Logger.debug(3, "Firmware debug message: " <> message)
  end

  @impl FarmbotFirmware.SideEffects
  def load_params do
    conf = Asset.firmware_config()
    known_params(conf)
  end

  def known_params(conf) do
    Map.take(conf, [
      :param_e_stop_on_mov_err,
      :param_mov_nr_retry,
      :movement_timeout_x,
      :movement_timeout_y,
      :movement_timeout_z,
      :movement_keep_active_x,
      :movement_keep_active_y,
      :movement_keep_active_z,
      :movement_home_at_boot_x,
      :movement_home_at_boot_y,
      :movement_home_at_boot_z,
      :movement_invert_endpoints_x,
      :movement_invert_endpoints_y,
      :movement_invert_endpoints_z,
      :movement_enable_endpoints_x,
      :movement_enable_endpoints_y,
      :movement_enable_endpoints_z,
      :movement_invert_motor_x,
      :movement_invert_motor_y,
      :movement_invert_motor_z,
      :movement_secondary_motor_x,
      :movement_secondary_motor_invert_x,
      :movement_steps_acc_dec_x,
      :movement_steps_acc_dec_y,
      :movement_steps_acc_dec_z,
      :movement_stop_at_home_x,
      :movement_stop_at_home_y,
      :movement_stop_at_home_z,
      :movement_home_up_x,
      :movement_home_up_y,
      :movement_home_up_z,
      :movement_step_per_mm_x,
      :movement_step_per_mm_y,
      :movement_step_per_mm_z,
      :movement_min_spd_x,
      :movement_min_spd_y,
      :movement_min_spd_z,
      :movement_home_spd_x,
      :movement_home_spd_y,
      :movement_home_spd_z,
      :movement_max_spd_x,
      :movement_max_spd_y,
      :movement_max_spd_z,
      :encoder_enabled_x,
      :encoder_enabled_y,
      :encoder_enabled_z,
      :encoder_type_x,
      :encoder_type_y,
      :encoder_type_z,
      :encoder_missed_steps_max_x,
      :encoder_missed_steps_max_y,
      :encoder_missed_steps_max_z,
      :encoder_scaling_x,
      :encoder_scaling_y,
      :encoder_scaling_z,
      :encoder_missed_steps_decay_x,
      :encoder_missed_steps_decay_y,
      :encoder_missed_steps_decay_z,
      :encoder_use_for_pos_x,
      :encoder_use_for_pos_y,
      :encoder_use_for_pos_z,
      :encoder_invert_x,
      :encoder_invert_y,
      :encoder_invert_z,
      :movement_axis_nr_steps_x,
      :movement_axis_nr_steps_y,
      :movement_axis_nr_steps_z,
      :movement_stop_at_max_x,
      :movement_stop_at_max_y,
      :movement_stop_at_max_z,
      :pin_guard_1_pin_nr,
      :pin_guard_1_time_out,
      :pin_guard_1_active_state,
      :pin_guard_2_pin_nr,
      :pin_guard_2_time_out,
      :pin_guard_2_active_state,
      :pin_guard_3_pin_nr,
      :pin_guard_3_time_out,
      :pin_guard_3_active_state,
      :pin_guard_4_pin_nr,
      :pin_guard_4_time_out,
      :pin_guard_4_active_state,
      :pin_guard_5_pin_nr,
      :pin_guard_5_time_out,
      :pin_guard_5_active_state
    ])
  end
end
