defmodule FarmbotOS.Asset.FirmwareConfigTest do
  use ExUnit.Case
  alias FarmbotOS.Asset.FirmwareConfig

  @keys [
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
  ]

  def fake_config() do
    Enum.reduce(@keys, %FirmwareConfig{}, fn key, state ->
      Map.put(state, key, 1.23)
    end)
  end

  test "render/1" do
    fwc = fake_config()
    result = FirmwareConfig.render(fwc)

    Enum.map(@keys, fn key ->
      expected = "#{key} == 1.23"
      actual = "#{key} == #{inspect(result[key])}"
      assert expected == actual
    end)
  end
end
