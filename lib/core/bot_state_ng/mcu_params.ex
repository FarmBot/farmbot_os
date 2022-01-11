defmodule FarmbotOS.BotStateNG.McuParams do
  @moduledoc false
  alias FarmbotOS.BotStateNG.McuParams
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field(:encoder_enabled_x, :float)
    field(:encoder_enabled_y, :float)
    field(:encoder_enabled_z, :float)
    field(:encoder_invert_x, :float)
    field(:encoder_invert_y, :float)
    field(:encoder_invert_z, :float)
    field(:encoder_missed_steps_decay_x, :float)
    field(:encoder_missed_steps_decay_y, :float)
    field(:encoder_missed_steps_decay_z, :float)
    field(:encoder_missed_steps_max_x, :float)
    field(:encoder_missed_steps_max_y, :float)
    field(:encoder_missed_steps_max_z, :float)
    field(:encoder_scaling_x, :float)
    field(:encoder_scaling_y, :float)
    field(:encoder_scaling_z, :float)
    field(:encoder_type_x, :float)
    field(:encoder_type_y, :float)
    field(:encoder_type_z, :float)
    field(:encoder_use_for_pos_x, :float)
    field(:encoder_use_for_pos_y, :float)
    field(:encoder_use_for_pos_z, :float)
    field(:movement_axis_nr_steps_x, :float)
    field(:movement_axis_nr_steps_y, :float)
    field(:movement_axis_nr_steps_z, :float)
    field(:movement_axis_stealth_x, :float)
    field(:movement_axis_stealth_y, :float)
    field(:movement_axis_stealth_z, :float)
    field(:movement_calibration_deadzone_x, :float)
    field(:movement_calibration_deadzone_y, :float)
    field(:movement_calibration_deadzone_z, :float)
    field(:movement_calibration_retry_total_x, :float)
    field(:movement_calibration_retry_total_y, :float)
    field(:movement_calibration_retry_total_z, :float)
    field(:movement_calibration_retry_x, :float)
    field(:movement_calibration_retry_y, :float)
    field(:movement_calibration_retry_z, :float)
    field(:movement_enable_endpoints_x, :float)
    field(:movement_enable_endpoints_y, :float)
    field(:movement_enable_endpoints_z, :float)
    field(:movement_home_at_boot_x, :float)
    field(:movement_home_at_boot_y, :float)
    field(:movement_home_at_boot_z, :float)
    field(:movement_home_spd_x, :float)
    field(:movement_home_spd_y, :float)
    field(:movement_home_spd_z, :float)
    field(:movement_home_up_x, :float)
    field(:movement_home_up_y, :float)
    field(:movement_home_up_z, :float)
    field(:movement_invert_2_endpoints_x, :float)
    field(:movement_invert_2_endpoints_y, :float)
    field(:movement_invert_2_endpoints_z, :float)
    field(:movement_invert_endpoints_x, :float)
    field(:movement_invert_endpoints_y, :float)
    field(:movement_invert_endpoints_z, :float)
    field(:movement_invert_motor_x, :float)
    field(:movement_invert_motor_y, :float)
    field(:movement_invert_motor_z, :float)
    field(:movement_keep_active_x, :float)
    field(:movement_keep_active_y, :float)
    field(:movement_keep_active_z, :float)
    field(:movement_max_spd_x, :float)
    field(:movement_max_spd_y, :float)
    field(:movement_max_spd_z, :float)
    field(:movement_max_spd_z2, :float)
    field(:movement_microsteps_x, :float)
    field(:movement_microsteps_y, :float)
    field(:movement_microsteps_z, :float)
    field(:movement_min_spd_x, :float)
    field(:movement_min_spd_y, :float)
    field(:movement_min_spd_z, :float)
    field(:movement_min_spd_z2, :float)
    field(:movement_motor_current_x, :float)
    field(:movement_motor_current_y, :float)
    field(:movement_motor_current_z, :float)
    field(:movement_secondary_motor_invert_x, :float)
    field(:movement_secondary_motor_x, :float)
    field(:movement_stall_sensitivity_x, :float)
    field(:movement_stall_sensitivity_y, :float)
    field(:movement_stall_sensitivity_z, :float)
    field(:movement_step_per_mm_x, :float)
    field(:movement_step_per_mm_y, :float)
    field(:movement_step_per_mm_z, :float)
    field(:movement_steps_acc_dec_x, :float)
    field(:movement_steps_acc_dec_y, :float)
    field(:movement_steps_acc_dec_z, :float)
    field(:movement_steps_acc_dec_z2, :float)
    field(:movement_stop_at_home_x, :float)
    field(:movement_stop_at_home_y, :float)
    field(:movement_stop_at_home_z, :float)
    field(:movement_stop_at_max_x, :float)
    field(:movement_stop_at_max_y, :float)
    field(:movement_stop_at_max_z, :float)
    field(:movement_timeout_x, :float)
    field(:movement_timeout_y, :float)
    field(:movement_timeout_z, :float)
    field(:param_e_stop_on_mov_err, :float)
    field(:param_mov_nr_retry, :float)
    field(:pin_guard_1_active_state, :float)
    field(:pin_guard_1_pin_nr, :float)
    field(:pin_guard_1_time_out, :float)
    field(:pin_guard_2_active_state, :float)
    field(:pin_guard_2_pin_nr, :float)
    field(:pin_guard_2_time_out, :float)
    field(:pin_guard_3_active_state, :float)
    field(:pin_guard_3_pin_nr, :float)
    field(:pin_guard_3_time_out, :float)
    field(:pin_guard_4_active_state, :float)
    field(:pin_guard_4_pin_nr, :float)
    field(:pin_guard_4_time_out, :float)
    field(:pin_guard_5_active_state, :float)
    field(:pin_guard_5_pin_nr, :float)
    field(:pin_guard_5_time_out, :float)
    field(:monitor, :boolean, default: true)
  end

  def new() do
    %McuParams{}
    |> changeset(%{})
    |> apply_changes()
  end

  def view(mcu_params) do
    %{
      encoder_enabled_x: mcu_params.encoder_enabled_x,
      encoder_enabled_y: mcu_params.encoder_enabled_y,
      encoder_enabled_z: mcu_params.encoder_enabled_z,
      encoder_invert_x: mcu_params.encoder_invert_x,
      encoder_invert_y: mcu_params.encoder_invert_y,
      encoder_invert_z: mcu_params.encoder_invert_z,
      encoder_missed_steps_decay_x: mcu_params.encoder_missed_steps_decay_x,
      encoder_missed_steps_decay_y: mcu_params.encoder_missed_steps_decay_y,
      encoder_missed_steps_decay_z: mcu_params.encoder_missed_steps_decay_z,
      encoder_missed_steps_max_x: mcu_params.encoder_missed_steps_max_x,
      encoder_missed_steps_max_y: mcu_params.encoder_missed_steps_max_y,
      encoder_missed_steps_max_z: mcu_params.encoder_missed_steps_max_z,
      encoder_scaling_x: mcu_params.encoder_scaling_x,
      encoder_scaling_y: mcu_params.encoder_scaling_y,
      encoder_scaling_z: mcu_params.encoder_scaling_z,
      encoder_type_x: mcu_params.encoder_type_x,
      encoder_type_y: mcu_params.encoder_type_y,
      encoder_type_z: mcu_params.encoder_type_z,
      encoder_use_for_pos_x: mcu_params.encoder_use_for_pos_x,
      encoder_use_for_pos_y: mcu_params.encoder_use_for_pos_y,
      encoder_use_for_pos_z: mcu_params.encoder_use_for_pos_z,
      movement_axis_nr_steps_x: mcu_params.movement_axis_nr_steps_x,
      movement_axis_nr_steps_y: mcu_params.movement_axis_nr_steps_y,
      movement_axis_nr_steps_z: mcu_params.movement_axis_nr_steps_z,
      movement_axis_stealth_x: mcu_params.movement_axis_stealth_x,
      movement_axis_stealth_y: mcu_params.movement_axis_stealth_y,
      movement_axis_stealth_z: mcu_params.movement_axis_stealth_z,
      movement_calibration_deadzone_x:
        mcu_params.movement_calibration_deadzone_x,
      movement_calibration_deadzone_y:
        mcu_params.movement_calibration_deadzone_y,
      movement_calibration_deadzone_z:
        mcu_params.movement_calibration_deadzone_z,
      movement_calibration_retry_total_x:
        mcu_params.movement_calibration_retry_total_x,
      movement_calibration_retry_total_y:
        mcu_params.movement_calibration_retry_total_y,
      movement_calibration_retry_total_z:
        mcu_params.movement_calibration_retry_total_z,
      movement_calibration_retry_x: mcu_params.movement_calibration_retry_x,
      movement_calibration_retry_y: mcu_params.movement_calibration_retry_y,
      movement_calibration_retry_z: mcu_params.movement_calibration_retry_z,
      movement_enable_endpoints_x: mcu_params.movement_enable_endpoints_x,
      movement_enable_endpoints_y: mcu_params.movement_enable_endpoints_y,
      movement_enable_endpoints_z: mcu_params.movement_enable_endpoints_z,
      movement_home_at_boot_x: mcu_params.movement_home_at_boot_x,
      movement_home_at_boot_y: mcu_params.movement_home_at_boot_y,
      movement_home_at_boot_z: mcu_params.movement_home_at_boot_z,
      movement_home_spd_x: mcu_params.movement_home_spd_x,
      movement_home_spd_y: mcu_params.movement_home_spd_y,
      movement_home_spd_z: mcu_params.movement_home_spd_z,
      movement_home_up_x: mcu_params.movement_home_up_x,
      movement_home_up_y: mcu_params.movement_home_up_y,
      movement_home_up_z: mcu_params.movement_home_up_z,
      movement_invert_2_endpoints_x: mcu_params.movement_invert_2_endpoints_x,
      movement_invert_2_endpoints_y: mcu_params.movement_invert_2_endpoints_y,
      movement_invert_2_endpoints_z: mcu_params.movement_invert_2_endpoints_z,
      movement_invert_endpoints_x: mcu_params.movement_invert_endpoints_x,
      movement_invert_endpoints_y: mcu_params.movement_invert_endpoints_y,
      movement_invert_endpoints_z: mcu_params.movement_invert_endpoints_z,
      movement_invert_motor_x: mcu_params.movement_invert_motor_x,
      movement_invert_motor_y: mcu_params.movement_invert_motor_y,
      movement_invert_motor_z: mcu_params.movement_invert_motor_z,
      movement_keep_active_x: mcu_params.movement_keep_active_x,
      movement_keep_active_y: mcu_params.movement_keep_active_y,
      movement_keep_active_z: mcu_params.movement_keep_active_z,
      movement_max_spd_x: mcu_params.movement_max_spd_x,
      movement_max_spd_y: mcu_params.movement_max_spd_y,
      movement_max_spd_z: mcu_params.movement_max_spd_z,
      movement_max_spd_z2: mcu_params.movement_max_spd_z2,
      movement_microsteps_x: mcu_params.movement_microsteps_x,
      movement_microsteps_y: mcu_params.movement_microsteps_y,
      movement_microsteps_z: mcu_params.movement_microsteps_z,
      movement_min_spd_x: mcu_params.movement_min_spd_x,
      movement_min_spd_y: mcu_params.movement_min_spd_y,
      movement_min_spd_z: mcu_params.movement_min_spd_z,
      movement_min_spd_z2: mcu_params.movement_min_spd_z2,
      movement_motor_current_x: mcu_params.movement_motor_current_x,
      movement_motor_current_y: mcu_params.movement_motor_current_y,
      movement_motor_current_z: mcu_params.movement_motor_current_z,
      movement_secondary_motor_invert_x:
        mcu_params.movement_secondary_motor_invert_x,
      movement_secondary_motor_x: mcu_params.movement_secondary_motor_x,
      movement_stall_sensitivity_x: mcu_params.movement_stall_sensitivity_x,
      movement_stall_sensitivity_y: mcu_params.movement_stall_sensitivity_y,
      movement_stall_sensitivity_z: mcu_params.movement_stall_sensitivity_z,
      movement_step_per_mm_x: mcu_params.movement_step_per_mm_x,
      movement_step_per_mm_y: mcu_params.movement_step_per_mm_y,
      movement_step_per_mm_z: mcu_params.movement_step_per_mm_z,
      movement_steps_acc_dec_x: mcu_params.movement_steps_acc_dec_x,
      movement_steps_acc_dec_y: mcu_params.movement_steps_acc_dec_y,
      movement_steps_acc_dec_z: mcu_params.movement_steps_acc_dec_z,
      movement_steps_acc_dec_z2: mcu_params.movement_steps_acc_dec_z2,
      movement_stop_at_home_x: mcu_params.movement_stop_at_home_x,
      movement_stop_at_home_y: mcu_params.movement_stop_at_home_y,
      movement_stop_at_home_z: mcu_params.movement_stop_at_home_z,
      movement_stop_at_max_x: mcu_params.movement_stop_at_max_x,
      movement_stop_at_max_y: mcu_params.movement_stop_at_max_y,
      movement_stop_at_max_z: mcu_params.movement_stop_at_max_z,
      movement_timeout_x: mcu_params.movement_timeout_x,
      movement_timeout_y: mcu_params.movement_timeout_y,
      movement_timeout_z: mcu_params.movement_timeout_z,
      param_e_stop_on_mov_err: mcu_params.param_e_stop_on_mov_err,
      param_mov_nr_retry: mcu_params.param_mov_nr_retry,
      pin_guard_1_active_state: mcu_params.pin_guard_1_active_state,
      pin_guard_1_pin_nr: mcu_params.pin_guard_1_pin_nr,
      pin_guard_1_time_out: mcu_params.pin_guard_1_time_out,
      pin_guard_2_active_state: mcu_params.pin_guard_2_active_state,
      pin_guard_2_pin_nr: mcu_params.pin_guard_2_pin_nr,
      pin_guard_2_time_out: mcu_params.pin_guard_2_time_out,
      pin_guard_3_active_state: mcu_params.pin_guard_3_active_state,
      pin_guard_3_pin_nr: mcu_params.pin_guard_3_pin_nr,
      pin_guard_3_time_out: mcu_params.pin_guard_3_time_out,
      pin_guard_4_active_state: mcu_params.pin_guard_4_active_state,
      pin_guard_4_pin_nr: mcu_params.pin_guard_4_pin_nr,
      pin_guard_4_time_out: mcu_params.pin_guard_4_time_out,
      pin_guard_5_active_state: mcu_params.pin_guard_5_active_state,
      pin_guard_5_pin_nr: mcu_params.pin_guard_5_pin_nr,
      pin_guard_5_time_out: mcu_params.pin_guard_5_time_out
    }
  end

  def changeset(mcu_params, params \\ %{}) do
    mcu_params
    |> cast(params, [
      :encoder_enabled_x,
      :encoder_enabled_y,
      :encoder_enabled_z,
      :encoder_invert_x,
      :encoder_invert_y,
      :encoder_invert_z,
      :encoder_missed_steps_decay_x,
      :encoder_missed_steps_decay_y,
      :encoder_missed_steps_decay_z,
      :encoder_missed_steps_max_x,
      :encoder_missed_steps_max_y,
      :encoder_missed_steps_max_z,
      :encoder_scaling_x,
      :encoder_scaling_y,
      :encoder_scaling_z,
      :encoder_type_x,
      :encoder_type_y,
      :encoder_type_z,
      :encoder_use_for_pos_x,
      :encoder_use_for_pos_y,
      :encoder_use_for_pos_z,
      :movement_axis_nr_steps_x,
      :movement_axis_nr_steps_y,
      :movement_axis_nr_steps_z,
      :movement_axis_stealth_x,
      :movement_axis_stealth_y,
      :movement_axis_stealth_z,
      :movement_calibration_deadzone_x,
      :movement_calibration_deadzone_y,
      :movement_calibration_deadzone_z,
      :movement_calibration_retry_total_x,
      :movement_calibration_retry_total_y,
      :movement_calibration_retry_total_z,
      :movement_calibration_retry_x,
      :movement_calibration_retry_y,
      :movement_calibration_retry_z,
      :movement_enable_endpoints_x,
      :movement_enable_endpoints_y,
      :movement_enable_endpoints_z,
      :movement_home_at_boot_x,
      :movement_home_at_boot_y,
      :movement_home_at_boot_z,
      :movement_home_spd_x,
      :movement_home_spd_y,
      :movement_home_spd_z,
      :movement_home_up_x,
      :movement_home_up_y,
      :movement_home_up_z,
      :movement_invert_2_endpoints_x,
      :movement_invert_2_endpoints_y,
      :movement_invert_2_endpoints_z,
      :movement_invert_endpoints_x,
      :movement_invert_endpoints_y,
      :movement_invert_endpoints_z,
      :movement_invert_motor_x,
      :movement_invert_motor_y,
      :movement_invert_motor_z,
      :movement_keep_active_x,
      :movement_keep_active_y,
      :movement_keep_active_z,
      :movement_max_spd_x,
      :movement_max_spd_y,
      :movement_max_spd_z,
      :movement_max_spd_z2,
      :movement_microsteps_x,
      :movement_microsteps_y,
      :movement_microsteps_z,
      :movement_min_spd_x,
      :movement_min_spd_y,
      :movement_min_spd_z,
      :movement_min_spd_z2,
      :movement_motor_current_x,
      :movement_motor_current_y,
      :movement_motor_current_z,
      :movement_secondary_motor_invert_x,
      :movement_secondary_motor_x,
      :movement_stall_sensitivity_x,
      :movement_stall_sensitivity_y,
      :movement_stall_sensitivity_z,
      :movement_step_per_mm_x,
      :movement_step_per_mm_y,
      :movement_step_per_mm_z,
      :movement_steps_acc_dec_x,
      :movement_steps_acc_dec_y,
      :movement_steps_acc_dec_z,
      :movement_steps_acc_dec_z2,
      :movement_stop_at_home_x,
      :movement_stop_at_home_y,
      :movement_stop_at_home_z,
      :movement_stop_at_max_x,
      :movement_stop_at_max_y,
      :movement_stop_at_max_z,
      :movement_timeout_x,
      :movement_timeout_y,
      :movement_timeout_z,
      :param_e_stop_on_mov_err,
      :param_mov_nr_retry,
      :pin_guard_1_active_state,
      :pin_guard_1_pin_nr,
      :pin_guard_1_time_out,
      :pin_guard_2_active_state,
      :pin_guard_2_pin_nr,
      :pin_guard_2_time_out,
      :pin_guard_3_active_state,
      :pin_guard_3_pin_nr,
      :pin_guard_3_time_out,
      :pin_guard_4_active_state,
      :pin_guard_4_pin_nr,
      :pin_guard_4_time_out,
      :pin_guard_5_active_state,
      :pin_guard_5_pin_nr,
      :pin_guard_5_time_out
    ])
  end
end
