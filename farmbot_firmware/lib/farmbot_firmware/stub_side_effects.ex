defmodule FarmbotFirmware.StubSideEffects do
  @behaviour FarmbotFirmware.SideEffects

  def load_params do
    [
      movement_home_spd_z: 200.0,
      movement_step_per_mm_x: 5.0,
      movement_min_spd_z: 200.0,
      movement_home_at_boot_z: 1.0,
      pin_guard_5_active_state: 1.0,
      encoder_missed_steps_decay_z: 5.0,
      movement_step_per_mm_y: 5.0,
      pin_guard_1_active_state: 1.0,
      movement_max_spd_z: 400.0,
      movement_invert_2_endpoints_y: 0.0,
      movement_home_up_y: 0.0,
      pin_guard_5_pin_nr: 0.0,
      encoder_use_for_pos_y: 1.0,
      encoder_enabled_z: 1.0,
      encoder_use_for_pos_z: 1.0,
      movement_home_up_x: 0.0,
      encoder_missed_steps_max_z: 5.0,
      pin_guard_3_active_state: 1.0,
      movement_keep_active_y: 0.0,
      movement_timeout_z: 120.0,
      encoder_invert_x: 0.0,
      movement_home_spd_y: 400.0,
      param_e_stop_on_mov_err: 0.0,
      pin_guard_4_pin_nr: 0.0,
      movement_axis_nr_steps_z: 7050.0,
      movement_steps_acc_dec_x: 100.0,
      movement_invert_motor_z: 0.0,
      encoder_scaling_x: 5556.0,
      movement_home_spd_x: 400.0,
      movement_keep_active_x: 0.0,
      movement_enable_endpoints_z: 0.0,
      movement_invert_endpoints_y: 0.0,
      encoder_missed_steps_max_x: 5.0,
      movement_stop_at_max_x: 1.0,
      pin_guard_4_active_state: 1.0,
      movement_secondary_motor_x: 1.0,
      encoder_invert_y: 0.0,
      movement_axis_nr_steps_y: 1686.0,
      movement_invert_2_endpoints_z: 0.0,
      movement_timeout_x: 120.0,
      encoder_missed_steps_max_y: 5.0,
      movement_stop_at_home_x: 1.0,
      pin_guard_4_time_out: 60.0,
      movement_secondary_motor_invert_x: 1.0,
      movement_invert_endpoints_z: 0.0,
      movement_steps_acc_dec_y: 100.0,
      encoder_invert_z: 0.0,
      movement_home_at_boot_y: 1.0,
      encoder_scaling_y: 5556.0,
      movement_invert_2_endpoints_x: 0.0,
      movement_steps_acc_dec_z: 300.0,
      encoder_type_z: 0.0,
      encoder_type_y: 0.0,
      encoder_use_for_pos_x: 1.0,
      movement_enable_endpoints_y: 0.0,
      movement_invert_endpoints_x: 0.0,
      pin_guard_2_active_state: 1.0,
      movement_invert_motor_x: 0.0,
      movement_keep_active_z: 1.0,
      movement_stop_at_max_z: 1.0,
      pin_guard_5_time_out: 60.0,
      movement_min_spd_x: 250.0,
      movement_timeout_y: 120.0,
      encoder_missed_steps_decay_y: 5.0,
      movement_max_spd_x: 800.0,
      encoder_enabled_x: 1.0,
      pin_guard_1_pin_nr: 0.0,
      movement_home_at_boot_x: 1.0,
      movement_min_spd_y: 350.0,
      movement_invert_motor_y: 0.0,
      param_mov_nr_retry: 3.0,
      pin_guard_2_pin_nr: 0.0,
      movement_home_up_z: 1.0,
      movement_axis_nr_steps_x: 1342.0,
      encoder_enabled_y: 1.0,
      movement_stop_at_max_y: 1.0,
      movement_stop_at_home_z: 1.0,
      movement_step_per_mm_z: 25.0,
      pin_guard_3_time_out: 60.0,
      encoder_type_x: 0.0,
      pin_guard_1_time_out: 60.0,
      movement_enable_endpoints_x: 0.0,
      movement_max_spd_y: 800.0,
      pin_guard_3_pin_nr: 0.0,
      movement_stop_at_home_y: 1.0,
      pin_guard_2_time_out: 60.0,
      encoder_scaling_z: 5556.0,
      encoder_missed_steps_decay_x: 5.0
    ]
  end

  def handle_position(_), do: :noop

  def handle_position_change(_), do: :noop

  def handle_axis_state(_), do: :noop

  def handle_calibration_state(_), do: :noop

  def handle_encoders_scaled(_), do: :noop

  def handle_encoders_raw(_), do: :noop

  def handle_paramater_value(_), do: :noop

  def handle_end_stops(_), do: :noop

  def handle_emergency_lock(), do: :noop

  def handle_emergency_unlock(), do: :noop

  def handle_pin_value(_), do: :noop

  def handle_software_version(_), do: :noop

  def handle_busy(_), do: :noop

  def handle_idle(_), do: :noop

  def handle_input_gcode(_), do: :noop

  def handle_output_gcode(_), do: :noop

  def handle_debug_message(_), do: :noop
end
