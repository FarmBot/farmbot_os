defmodule FarmbotOS.Asset.FirmwareConfig do
  @moduledoc """
  """

  use FarmbotOS.Asset.Schema, path: "/api/firmware_config"

  schema "firmware_configs" do
    field(:id, :id)

    has_one(:local_meta, FarmbotOS.Asset.Private.LocalMeta,
      on_delete: :delete_all,
      references: :local_id,
      foreign_key: :asset_local_id
    )

    field(:api_migrated, :boolean)
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
    field(:monitor, :boolean, default: true)
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
    field(:pin_report_1_pin_nr, :float)
    field(:pin_report_2_pin_nr, :float)
    timestamps()
  end

  view firmware_config do
    %{
      id: firmware_config.id,
      updated_at: firmware_config.updated_at,
      api_migrated: firmware_config.api_migrated,
      encoder_enabled_x: firmware_config.encoder_enabled_x,
      encoder_enabled_y: firmware_config.encoder_enabled_y,
      encoder_enabled_z: firmware_config.encoder_enabled_z,
      encoder_invert_x: firmware_config.encoder_invert_x,
      encoder_invert_y: firmware_config.encoder_invert_y,
      encoder_invert_z: firmware_config.encoder_invert_z,
      encoder_missed_steps_decay_x:
        firmware_config.encoder_missed_steps_decay_x,
      encoder_missed_steps_decay_y:
        firmware_config.encoder_missed_steps_decay_y,
      encoder_missed_steps_decay_z:
        firmware_config.encoder_missed_steps_decay_z,
      encoder_missed_steps_max_x: firmware_config.encoder_missed_steps_max_x,
      encoder_missed_steps_max_y: firmware_config.encoder_missed_steps_max_y,
      encoder_missed_steps_max_z: firmware_config.encoder_missed_steps_max_z,
      encoder_scaling_x: firmware_config.encoder_scaling_x,
      encoder_scaling_y: firmware_config.encoder_scaling_y,
      encoder_scaling_z: firmware_config.encoder_scaling_z,
      encoder_type_x: firmware_config.encoder_type_x,
      encoder_type_y: firmware_config.encoder_type_y,
      encoder_type_z: firmware_config.encoder_type_z,
      encoder_use_for_pos_x: firmware_config.encoder_use_for_pos_x,
      encoder_use_for_pos_y: firmware_config.encoder_use_for_pos_y,
      encoder_use_for_pos_z: firmware_config.encoder_use_for_pos_z,
      movement_axis_nr_steps_x: firmware_config.movement_axis_nr_steps_x,
      movement_axis_nr_steps_y: firmware_config.movement_axis_nr_steps_y,
      movement_axis_nr_steps_z: firmware_config.movement_axis_nr_steps_z,
      movement_axis_stealth_x: firmware_config.movement_axis_stealth_x,
      movement_axis_stealth_y: firmware_config.movement_axis_stealth_y,
      movement_axis_stealth_z: firmware_config.movement_axis_stealth_z,
      movement_calibration_deadzone_x:
        firmware_config.movement_calibration_deadzone_x,
      movement_calibration_deadzone_y:
        firmware_config.movement_calibration_deadzone_y,
      movement_calibration_deadzone_z:
        firmware_config.movement_calibration_deadzone_z,
      movement_calibration_retry_x:
        firmware_config.movement_calibration_retry_x,
      movement_calibration_retry_y:
        firmware_config.movement_calibration_retry_y,
      movement_calibration_retry_z:
        firmware_config.movement_calibration_retry_z,
      movement_enable_endpoints_x: firmware_config.movement_enable_endpoints_x,
      movement_enable_endpoints_y: firmware_config.movement_enable_endpoints_y,
      movement_enable_endpoints_z: firmware_config.movement_enable_endpoints_z,
      movement_home_at_boot_x: firmware_config.movement_home_at_boot_x,
      movement_home_at_boot_y: firmware_config.movement_home_at_boot_y,
      movement_home_at_boot_z: firmware_config.movement_home_at_boot_z,
      movement_home_spd_x: firmware_config.movement_home_spd_x,
      movement_home_spd_y: firmware_config.movement_home_spd_y,
      movement_home_spd_z: firmware_config.movement_home_spd_z,
      movement_home_up_x: firmware_config.movement_home_up_x,
      movement_home_up_y: firmware_config.movement_home_up_y,
      movement_home_up_z: firmware_config.movement_home_up_z,
      movement_invert_2_endpoints_x:
        firmware_config.movement_invert_2_endpoints_x,
      movement_invert_2_endpoints_y:
        firmware_config.movement_invert_2_endpoints_y,
      movement_invert_2_endpoints_z:
        firmware_config.movement_invert_2_endpoints_z,
      movement_invert_endpoints_x: firmware_config.movement_invert_endpoints_x,
      movement_invert_endpoints_y: firmware_config.movement_invert_endpoints_y,
      movement_invert_endpoints_z: firmware_config.movement_invert_endpoints_z,
      movement_invert_motor_x: firmware_config.movement_invert_motor_x,
      movement_invert_motor_y: firmware_config.movement_invert_motor_y,
      movement_invert_motor_z: firmware_config.movement_invert_motor_z,
      movement_keep_active_x: firmware_config.movement_keep_active_x,
      movement_keep_active_y: firmware_config.movement_keep_active_y,
      movement_keep_active_z: firmware_config.movement_keep_active_z,
      movement_max_spd_x: firmware_config.movement_max_spd_x,
      movement_max_spd_y: firmware_config.movement_max_spd_y,
      movement_max_spd_z: firmware_config.movement_max_spd_z,
      movement_max_spd_z2: firmware_config.movement_max_spd_z2,
      movement_microsteps_x: firmware_config.movement_microsteps_x,
      movement_microsteps_y: firmware_config.movement_microsteps_y,
      movement_microsteps_z: firmware_config.movement_microsteps_z,
      movement_min_spd_x: firmware_config.movement_min_spd_x,
      movement_min_spd_y: firmware_config.movement_min_spd_y,
      movement_min_spd_z: firmware_config.movement_min_spd_z,
      movement_min_spd_z2: firmware_config.movement_min_spd_z2,
      movement_calibration_retry_total_x:
        firmware_config.movement_calibration_retry_total_x,
      movement_calibration_retry_total_y:
        firmware_config.movement_calibration_retry_total_y,
      movement_calibration_retry_total_z:
        firmware_config.movement_calibration_retry_total_z,
      movement_motor_current_x: firmware_config.movement_motor_current_x,
      movement_motor_current_y: firmware_config.movement_motor_current_y,
      movement_motor_current_z: firmware_config.movement_motor_current_z,
      movement_secondary_motor_invert_x:
        firmware_config.movement_secondary_motor_invert_x,
      movement_secondary_motor_x: firmware_config.movement_secondary_motor_x,
      movement_stall_sensitivity_x:
        firmware_config.movement_stall_sensitivity_x,
      movement_stall_sensitivity_y:
        firmware_config.movement_stall_sensitivity_y,
      movement_stall_sensitivity_z:
        firmware_config.movement_stall_sensitivity_z,
      movement_step_per_mm_x: firmware_config.movement_step_per_mm_x,
      movement_step_per_mm_y: firmware_config.movement_step_per_mm_y,
      movement_step_per_mm_z: firmware_config.movement_step_per_mm_z,
      movement_steps_acc_dec_x: firmware_config.movement_steps_acc_dec_x,
      movement_steps_acc_dec_y: firmware_config.movement_steps_acc_dec_y,
      movement_steps_acc_dec_z: firmware_config.movement_steps_acc_dec_z,
      movement_steps_acc_dec_z2: firmware_config.movement_steps_acc_dec_z2,
      movement_stop_at_home_x: firmware_config.movement_stop_at_home_x,
      movement_stop_at_home_y: firmware_config.movement_stop_at_home_y,
      movement_stop_at_home_z: firmware_config.movement_stop_at_home_z,
      movement_stop_at_max_x: firmware_config.movement_stop_at_max_x,
      movement_stop_at_max_y: firmware_config.movement_stop_at_max_y,
      movement_stop_at_max_z: firmware_config.movement_stop_at_max_z,
      movement_timeout_x: firmware_config.movement_timeout_x,
      movement_timeout_y: firmware_config.movement_timeout_y,
      movement_timeout_z: firmware_config.movement_timeout_z,
      param_e_stop_on_mov_err: firmware_config.param_e_stop_on_mov_err,
      param_mov_nr_retry: firmware_config.param_mov_nr_retry,
      pin_guard_1_active_state: firmware_config.pin_guard_1_active_state,
      pin_guard_1_pin_nr: firmware_config.pin_guard_1_pin_nr,
      pin_guard_1_time_out: firmware_config.pin_guard_1_time_out,
      pin_guard_2_active_state: firmware_config.pin_guard_2_active_state,
      pin_guard_2_pin_nr: firmware_config.pin_guard_2_pin_nr,
      pin_guard_2_time_out: firmware_config.pin_guard_2_time_out,
      pin_guard_3_active_state: firmware_config.pin_guard_3_active_state,
      pin_guard_3_pin_nr: firmware_config.pin_guard_3_pin_nr,
      pin_guard_3_time_out: firmware_config.pin_guard_3_time_out,
      pin_guard_4_active_state: firmware_config.pin_guard_4_active_state,
      pin_guard_4_pin_nr: firmware_config.pin_guard_4_pin_nr,
      pin_guard_4_time_out: firmware_config.pin_guard_4_time_out,
      pin_guard_5_active_state: firmware_config.pin_guard_5_active_state,
      pin_guard_5_pin_nr: firmware_config.pin_guard_5_pin_nr,
      pin_guard_5_time_out: firmware_config.pin_guard_5_time_out,
      pin_report_1_pin_nr: firmware_config.pin_report_1_pin_nr,
      pin_report_2_pin_nr: firmware_config.pin_report_2_pin_nr
    }
  end

  def changeset(firmware_config, params \\ %{}) do
    firmware_config
    |> cast(params, [
      :id,
      :api_migrated,
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
      :movement_calibration_retry_total_x,
      :movement_calibration_retry_total_y,
      :movement_calibration_retry_total_z,
      :pin_report_1_pin_nr,
      :pin_report_2_pin_nr,
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
      :pin_guard_5_time_out,
      :monitor,
      :created_at,
      :updated_at
    ])
    |> validate_required([])
  end
end
