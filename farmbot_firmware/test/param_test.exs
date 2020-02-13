defmodule FarmbotFirmware.ParamTest do
  use ExUnit.Case
  alias FarmbotFirmware.Param

  test "to_human()" do
    float_value = 1.23
    seconds = "(seconds)"
    steps = "(steps)"
    steps_per_s = "(steps/s)"
    steps_per_mm = "(steps/mm)"

    assert Param.to_human(:param_test, 1) ==
             {"param_test", nil, true}

    assert Param.to_human(:param_config_ok, 1) ==
             {"param_config_ok", nil, true}

    assert Param.to_human(:param_use_eeprom, 1) ==
             {"use eeprom", nil, true}

    assert Param.to_human(:param_e_stop_on_mov_err, 1) ==
             {"e-stop on movement errors", nil, true}

    assert Param.to_human(:movement_timeout_x, float_value) ==
             {"timeout after, x-axis", seconds, "1.2"}

    assert Param.to_human(:movement_timeout_y, float_value) ==
             {"timeout after, y-axis", seconds, "1.2"}

    assert Param.to_human(:movement_timeout_z, float_value) ==
             {"timeout after, z-axis", seconds, "1.2"}

    assert Param.to_human(:movement_keep_active_x, 1) ==
             {"always power motors, x-axis", nil, true}

    assert Param.to_human(:movement_keep_active_y, 1) ==
             {"always power motors, y-axis", nil, true}

    assert Param.to_human(:movement_keep_active_z, 1) ==
             {"always power motors, z-axis", nil, true}

    assert Param.to_human(:movement_home_at_boot_x, 1) ==
             {"find home on boot, x-axis", nil, true}

    assert Param.to_human(:movement_home_at_boot_y, 1) ==
             {"find home on boot, y-axis", nil, true}

    assert Param.to_human(:movement_home_at_boot_z, 1) ==
             {"find home on boot, z-axis", nil, true}

    assert Param.to_human(:movement_invert_endpoints_x, 1) ==
             {"swap endstops, x-axis", nil, true}

    assert Param.to_human(:movement_invert_endpoints_y, 1) ==
             {"swap endstops, y-axis", nil, true}

    assert Param.to_human(:movement_invert_endpoints_z, 1) ==
             {"swap endstops, z-axis", nil, true}

    assert Param.to_human(:movement_enable_endpoints_x, 1) ==
             {"enable endstops, x-axis", nil, true}

    assert Param.to_human(:movement_enable_endpoints_y, 1) ==
             {"enable endstops, y-axis", nil, true}

    assert Param.to_human(:movement_enable_endpoints_z, 1) ==
             {"enable endstops, z-axis", nil, true}

    assert Param.to_human(:movement_invert_motor_x, 1) ==
             {"invert motor, x-axis", nil, true}

    assert Param.to_human(:movement_invert_motor_y, 1) ==
             {"invert motor, y-axis", nil, true}

    assert Param.to_human(:movement_invert_motor_z, 1) ==
             {"invert motor, z-axis", nil, true}

    assert Param.to_human(:movement_secondary_motor_x, 1) ==
             {"enable 2nd x motor", nil, true}

    assert Param.to_human(:movement_secondary_motor_invert_x, 1) ==
             {"invert 2nd x motor", nil, true}

    assert Param.to_human(:movement_stop_at_home_x, 1) ==
             {"stop at home, x-axis", nil, true}

    assert Param.to_human(:movement_stop_at_home_y, 1) ==
             {"stop at home, y-axis", nil, true}

    assert Param.to_human(:movement_stop_at_home_z, 1) ==
             {"stop at home, z-axis", nil, true}

    assert Param.to_human(:movement_step_per_mm_x, float_value) ==
             {"steps per mm, x-axis", steps_per_mm, "1.2"}

    assert Param.to_human(:movement_step_per_mm_y, float_value) ==
             {"steps per mm, y-axis", steps_per_mm, "1.2"}

    assert Param.to_human(:movement_step_per_mm_z, float_value) ==
             {"steps per mm, z-axis", steps_per_mm, "1.2"}

    assert Param.to_human(:movement_min_spd_x, float_value) ==
             {"minimum speed, x-axis", steps_per_s, "1.2"}

    assert Param.to_human(:movement_min_spd_y, float_value) ==
             {"minimum speed, y-axis", steps_per_s, "1.2"}

    assert Param.to_human(:movement_min_spd_z, float_value) ==
             {"minimum speed, z-axis", steps_per_s, "1.2"}

    assert Param.to_human(:movement_home_spd_x, float_value) ==
             {"homing speed, x-axis", steps_per_s, "1.2"}

    assert Param.to_human(:movement_home_spd_y, float_value) ==
             {"homing speed, y-axis", steps_per_s, "1.2"}

    assert Param.to_human(:movement_home_spd_z, float_value) ==
             {"homing speed, z-axis", steps_per_s, "1.2"}

    assert Param.to_human(:movement_max_spd_x, float_value) ==
             {"max speed, x-axis", steps_per_s, "1.2"}

    assert Param.to_human(:movement_max_spd_y, float_value) ==
             {"max speed, y-axis", steps_per_s, "1.2"}

    assert Param.to_human(:movement_max_spd_z, float_value) ==
             {"max speed, z-axis", steps_per_s, "1.2"}

    assert Param.to_human(:movement_invert_2_endpoints_x, 1) ==
             {"invert endstops, x-axis", nil, true}

    assert Param.to_human(:movement_invert_2_endpoints_y, 1) ==
             {"invert endstops, y-axis", nil, true}

    assert Param.to_human(:movement_invert_2_endpoints_z, 1) ==
             {"invert endstops, z-axis", nil, true}

    assert Param.to_human(:encoder_enabled_x, 1) ==
             {"enable encoders / stall detection, x-axis", nil, true}

    assert Param.to_human(:encoder_enabled_y, 1) ==
             {"enable encoders / stall detection, y-axis", nil, true}

    assert Param.to_human(:encoder_enabled_z, 1) ==
             {"enable encoders / stall detection, z-axis", nil, true}

    assert Param.to_human(:encoder_type_x, float_value) ==
             {"encoder type, x-axis", nil, "1.2"}

    assert Param.to_human(:encoder_type_y, float_value) ==
             {"encoder type, y-axis", nil, "1.2"}

    assert Param.to_human(:encoder_type_z, float_value) ==
             {"encoder type, z-axis", nil, "1.2"}

    assert Param.to_human(:encoder_scaling_x, float_value) ==
             {"encoder scaling, x-axis", nil, "1.2"}

    assert Param.to_human(:encoder_scaling_y, float_value) ==
             {"encoder scaling, y-axis", nil, "1.2"}

    assert Param.to_human(:encoder_scaling_z, float_value) ==
             {"encoder scaling, z-axis", nil, "1.2"}

    assert Param.to_human(:encoder_missed_steps_decay_x, float_value) ==
             {"missed step decay, x-axis", steps, "1.2"}

    assert Param.to_human(:encoder_missed_steps_decay_y, float_value) ==
             {"missed step decay, y-axis", steps, "1.2"}

    assert Param.to_human(:encoder_missed_steps_decay_z, float_value) ==
             {"missed step decay, z-axis", steps, "1.2"}

    assert Param.to_human(:encoder_use_for_pos_x, 1) ==
             {"use encoders for positioning, x-axis", nil, true}

    assert Param.to_human(:encoder_use_for_pos_y, 1) ==
             {"use encoders for positioning, y-axis", nil, true}

    assert Param.to_human(:encoder_use_for_pos_z, 1) ==
             {"use encoders for positioning, z-axis", nil, true}

    assert Param.to_human(:encoder_invert_x, 1) ==
             {"invert encoders, x-axis", nil, true}

    assert Param.to_human(:encoder_invert_y, 1) ==
             {"invert encoders, y-axis", nil, true}

    assert Param.to_human(:encoder_invert_z, 1) ==
             {"invert encoders, z-axis", nil, true}

    assert Param.to_human(:movement_stop_at_max_x, 1) ==
             {"stop at max, x-axis", nil, true}

    assert Param.to_human(:movement_stop_at_max_y, 1) ==
             {"stop at max, y-axis", nil, true}

    assert Param.to_human(:movement_stop_at_max_z, 1) ==
             {"stop at max, z-axis", nil, true}

    assert Param.to_human(:pin_guard_1_active_state, 0) ==
             {"pin guard 1 safe state", nil, "HIGH"}

    assert Param.to_human(:pin_guard_2_active_state, 0) ==
             {"pin guard 2 safe state", nil, "HIGH"}

    assert Param.to_human(:pin_guard_3_active_state, 0) ==
             {"pin guard 3 safe state", nil, "HIGH"}

    assert Param.to_human(:pin_guard_4_active_state, 0) ==
             {"pin guard 4 safe state", nil, "HIGH"}

    assert Param.to_human(:pin_guard_5_active_state, 0) ==
             {"pin guard 5 safe state", nil, "HIGH"}
  end

  test "Handling of uknown parameters" do
    assert :unknown_parameter == Param.decode(-999)
  end
end
