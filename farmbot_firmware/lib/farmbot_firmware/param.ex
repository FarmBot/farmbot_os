defmodule FarmbotFirmware.Param do
  @moduledoc "decodes/encodes integer id to name and vice versa"
  require Logger

  @type t() :: atom()

  @doc "Decodes an integer parameter id to a atom parameter name"
  def decode(parameter_id)
  def decode(0), do: :param_version
  def decode(1), do: :param_test
  def decode(2), do: :param_config_ok
  def decode(3), do: :param_use_eeprom
  def decode(4), do: :param_e_stop_on_mov_err
  def decode(5), do: :param_mov_nr_retry
  def decode(11), do: :movement_timeout_x
  def decode(12), do: :movement_timeout_y
  def decode(13), do: :movement_timeout_z
  def decode(15), do: :movement_keep_active_x
  def decode(16), do: :movement_keep_active_y
  def decode(17), do: :movement_keep_active_z
  def decode(18), do: :movement_home_at_boot_x
  def decode(19), do: :movement_home_at_boot_y
  def decode(20), do: :movement_home_at_boot_z
  def decode(21), do: :movement_invert_endpoints_x
  def decode(22), do: :movement_invert_endpoints_y
  def decode(23), do: :movement_invert_endpoints_z
  def decode(25), do: :movement_enable_endpoints_x
  def decode(26), do: :movement_enable_endpoints_y
  def decode(27), do: :movement_enable_endpoints_z
  def decode(31), do: :movement_invert_motor_x
  def decode(32), do: :movement_invert_motor_y
  def decode(33), do: :movement_invert_motor_z
  def decode(36), do: :movement_secondary_motor_x
  def decode(37), do: :movement_secondary_motor_invert_x
  def decode(41), do: :movement_steps_acc_dec_x
  def decode(42), do: :movement_steps_acc_dec_y
  def decode(43), do: :movement_steps_acc_dec_z
  def decode(45), do: :movement_stop_at_home_x
  def decode(46), do: :movement_stop_at_home_y
  def decode(47), do: :movement_stop_at_home_z
  def decode(51), do: :movement_home_up_x
  def decode(52), do: :movement_home_up_y
  def decode(53), do: :movement_home_up_z
  def decode(55), do: :movement_step_per_mm_x
  def decode(56), do: :movement_step_per_mm_y
  def decode(57), do: :movement_step_per_mm_z
  def decode(61), do: :movement_min_spd_x
  def decode(62), do: :movement_min_spd_y
  def decode(63), do: :movement_min_spd_z
  def decode(65), do: :movement_home_spd_x
  def decode(66), do: :movement_home_spd_y
  def decode(67), do: :movement_home_spd_z
  def decode(71), do: :movement_max_spd_x
  def decode(72), do: :movement_max_spd_y
  def decode(73), do: :movement_max_spd_z
  def decode(75), do: :movement_invert_2_endpoints_x
  def decode(76), do: :movement_invert_2_endpoints_y
  def decode(77), do: :movement_invert_2_endpoints_z
  def decode(81), do: :movement_motor_current_x
  def decode(82), do: :movement_motor_current_y
  def decode(83), do: :movement_motor_current_z
  def decode(85), do: :movement_stall_sensitivity_x
  def decode(86), do: :movement_stall_sensitivity_y
  def decode(87), do: :movement_stall_sensitivity_z
  def decode(101), do: :encoder_enabled_x
  def decode(102), do: :encoder_enabled_y
  def decode(103), do: :encoder_enabled_z
  def decode(105), do: :encoder_type_x
  def decode(106), do: :encoder_type_y
  def decode(107), do: :encoder_type_z
  def decode(111), do: :encoder_missed_steps_max_x
  def decode(112), do: :encoder_missed_steps_max_y
  def decode(113), do: :encoder_missed_steps_max_z
  def decode(115), do: :encoder_scaling_x
  def decode(116), do: :encoder_scaling_y
  def decode(117), do: :encoder_scaling_z
  def decode(121), do: :encoder_missed_steps_decay_x
  def decode(122), do: :encoder_missed_steps_decay_y
  def decode(123), do: :encoder_missed_steps_decay_z
  def decode(125), do: :encoder_use_for_pos_x
  def decode(126), do: :encoder_use_for_pos_y
  def decode(127), do: :encoder_use_for_pos_z
  def decode(131), do: :encoder_invert_x
  def decode(132), do: :encoder_invert_y
  def decode(133), do: :encoder_invert_z
  def decode(141), do: :movement_axis_nr_steps_x
  def decode(142), do: :movement_axis_nr_steps_y
  def decode(143), do: :movement_axis_nr_steps_z
  def decode(145), do: :movement_stop_at_max_x
  def decode(146), do: :movement_stop_at_max_y
  def decode(147), do: :movement_stop_at_max_z
  def decode(201), do: :pin_guard_1_pin_nr
  def decode(202), do: :pin_guard_1_time_out
  def decode(203), do: :pin_guard_1_active_state
  def decode(205), do: :pin_guard_2_pin_nr
  def decode(206), do: :pin_guard_2_time_out
  def decode(207), do: :pin_guard_2_active_state
  def decode(211), do: :pin_guard_3_pin_nr
  def decode(212), do: :pin_guard_3_time_out
  def decode(213), do: :pin_guard_3_active_state
  def decode(215), do: :pin_guard_4_pin_nr
  def decode(216), do: :pin_guard_4_time_out
  def decode(217), do: :pin_guard_4_active_state
  def decode(221), do: :pin_guard_5_pin_nr
  def decode(222), do: :pin_guard_5_time_out
  def decode(223), do: :pin_guard_5_active_state

  def decode(unknown) when is_integer(unknown) do
    Logger.error("unknown firmware parameter: #{unknown}")
    :unknown_parameter
  end

  @doc "Encodes an atom parameter name to an integer parameter id."
  def encode(parameter)
  def encode(:param_version), do: 0
  def encode(:param_test), do: 1
  def encode(:param_config_ok), do: 2
  def encode(:param_use_eeprom), do: 3
  def encode(:param_e_stop_on_mov_err), do: 4
  def encode(:param_mov_nr_retry), do: 5
  def encode(:movement_timeout_x), do: 11
  def encode(:movement_timeout_y), do: 12
  def encode(:movement_timeout_z), do: 13
  def encode(:movement_keep_active_x), do: 15
  def encode(:movement_keep_active_y), do: 16
  def encode(:movement_keep_active_z), do: 17
  def encode(:movement_home_at_boot_x), do: 18
  def encode(:movement_home_at_boot_y), do: 19
  def encode(:movement_home_at_boot_z), do: 20
  def encode(:movement_invert_endpoints_x), do: 21
  def encode(:movement_invert_endpoints_y), do: 22
  def encode(:movement_invert_endpoints_z), do: 23
  def encode(:movement_enable_endpoints_x), do: 25
  def encode(:movement_enable_endpoints_y), do: 26
  def encode(:movement_enable_endpoints_z), do: 27
  def encode(:movement_invert_motor_x), do: 31
  def encode(:movement_invert_motor_y), do: 32
  def encode(:movement_invert_motor_z), do: 33
  def encode(:movement_secondary_motor_x), do: 36
  def encode(:movement_secondary_motor_invert_x), do: 37
  def encode(:movement_steps_acc_dec_x), do: 41
  def encode(:movement_steps_acc_dec_y), do: 42
  def encode(:movement_steps_acc_dec_z), do: 43
  def encode(:movement_stop_at_home_x), do: 45
  def encode(:movement_stop_at_home_y), do: 46
  def encode(:movement_stop_at_home_z), do: 47
  def encode(:movement_home_up_x), do: 51
  def encode(:movement_home_up_y), do: 52
  def encode(:movement_home_up_z), do: 53
  def encode(:movement_step_per_mm_x), do: 55
  def encode(:movement_step_per_mm_y), do: 56
  def encode(:movement_step_per_mm_z), do: 57
  def encode(:movement_min_spd_x), do: 61
  def encode(:movement_min_spd_y), do: 62
  def encode(:movement_min_spd_z), do: 63
  def encode(:movement_home_spd_x), do: 65
  def encode(:movement_home_spd_y), do: 66
  def encode(:movement_home_spd_z), do: 67
  def encode(:movement_max_spd_x), do: 71
  def encode(:movement_max_spd_y), do: 72
  def encode(:movement_max_spd_z), do: 73
  def encode(:movement_invert_2_endpoints_x), do: 75
  def encode(:movement_invert_2_endpoints_y), do: 76
  def encode(:movement_invert_2_endpoints_z), do: 77
  def encode(:movement_motor_current_x), do: 81
  def encode(:movement_motor_current_y), do: 82
  def encode(:movement_motor_current_z), do: 83
  def encode(:movement_stall_sensitivity_x), do: 85
  def encode(:movement_stall_sensitivity_y), do: 86
  def encode(:movement_stall_sensitivity_z), do: 87
  def encode(:encoder_enabled_x), do: 101
  def encode(:encoder_enabled_y), do: 102
  def encode(:encoder_enabled_z), do: 103
  def encode(:encoder_type_x), do: 105
  def encode(:encoder_type_y), do: 106
  def encode(:encoder_type_z), do: 107
  def encode(:encoder_missed_steps_max_x), do: 111
  def encode(:encoder_missed_steps_max_y), do: 112
  def encode(:encoder_missed_steps_max_z), do: 113
  def encode(:encoder_scaling_x), do: 115
  def encode(:encoder_scaling_y), do: 116
  def encode(:encoder_scaling_z), do: 117
  def encode(:encoder_missed_steps_decay_x), do: 121
  def encode(:encoder_missed_steps_decay_y), do: 122
  def encode(:encoder_missed_steps_decay_z), do: 123
  def encode(:encoder_use_for_pos_x), do: 125
  def encode(:encoder_use_for_pos_y), do: 126
  def encode(:encoder_use_for_pos_z), do: 127
  def encode(:encoder_invert_x), do: 131
  def encode(:encoder_invert_y), do: 132
  def encode(:encoder_invert_z), do: 133
  def encode(:movement_axis_nr_steps_x), do: 141
  def encode(:movement_axis_nr_steps_y), do: 142
  def encode(:movement_axis_nr_steps_z), do: 143
  def encode(:movement_stop_at_max_x), do: 145
  def encode(:movement_stop_at_max_y), do: 146
  def encode(:movement_stop_at_max_z), do: 147
  def encode(:pin_guard_1_pin_nr), do: 201
  def encode(:pin_guard_1_time_out), do: 202
  def encode(:pin_guard_1_active_state), do: 203
  def encode(:pin_guard_2_pin_nr), do: 205
  def encode(:pin_guard_2_time_out), do: 206
  def encode(:pin_guard_2_active_state), do: 207
  def encode(:pin_guard_3_pin_nr), do: 211
  def encode(:pin_guard_3_time_out), do: 212
  def encode(:pin_guard_3_active_state), do: 213
  def encode(:pin_guard_4_pin_nr), do: 215
  def encode(:pin_guard_4_time_out), do: 216
  def encode(:pin_guard_4_active_state), do: 217
  def encode(:pin_guard_5_pin_nr), do: 221
  def encode(:pin_guard_5_time_out), do: 222
  def encode(:pin_guard_5_active_state), do: 223

  @typedoc "The human readable name of a param"
  @type human() :: String.t()

  @typedoc "Human readable units for param"
  @type unit() :: String.t()

  @seconds "(seconds)"
  @steps "(steps)"
  @steps_per_mm "(steps/mm)"
  @amps "(amps)"

  @doc "Translates a param to a human readable string"
  @spec to_human(parameter :: t() | number(), value :: number()) ::
          {human(), value :: String.t(), nil | unit()}
  def to_human(parameter, value)
  def to_human(id, value) when is_number(id), do: decode(id) |> to_human(value)

  def to_human(:param_version, value),
    do: {"param_version", nil, format_float(value)}

  def to_human(:param_test, value),
    do: {"param_test", nil, format_bool(value)}

  def to_human(:param_config_ok, value),
    do: {"param_config_ok", nil, format_bool(value)}

  def to_human(:param_use_eeprom, value),
    do: {"use eeprom", nil, format_bool(value)}

  def to_human(:param_e_stop_on_mov_err, value),
    do: {"e-stop on movement errors", nil, format_bool(value)}

  def to_human(:param_mov_nr_retry, value),
    do: {"max retries", nil, format_float(value)}

  def to_human(:movement_timeout_x, value),
    do: {"timeout after, x-axis", @seconds, format_float(value)}

  def to_human(:movement_timeout_y, value),
    do: {"timeout after, y-axis", @seconds, format_float(value)}

  def to_human(:movement_timeout_z, value),
    do: {"timeout after, z-axis", @seconds, format_float(value)}

  def to_human(:movement_keep_active_x, value),
    do: {"always power motors, x-axis", nil, format_bool(value)}

  def to_human(:movement_keep_active_y, value),
    do: {"always power motors, y-axis", nil, format_bool(value)}

  def to_human(:movement_keep_active_z, value),
    do: {"always power motors, z-axis", nil, format_bool(value)}

  def to_human(:movement_home_at_boot_x, value),
    do: {"find home on boot, x-axis", nil, format_bool(value)}

  def to_human(:movement_home_at_boot_y, value),
    do: {"find home on boot, y-axis", nil, format_bool(value)}

  def to_human(:movement_home_at_boot_z, value),
    do: {"find home on boot, z-axis", nil, format_bool(value)}

  def to_human(:movement_invert_endpoints_x, value),
    do: {"invert endstops, x-axis", nil, format_bool(value)}

  def to_human(:movement_invert_endpoints_y, value),
    do: {"invert endstops, y-axis", nil, format_bool(value)}

  def to_human(:movement_invert_endpoints_z, value),
    do: {"invert endstops, z-axis", nil, format_bool(value)}

  def to_human(:movement_enable_endpoints_x, value),
    do: {"enable endstops, x-axis", nil, format_bool(value)}

  def to_human(:movement_enable_endpoints_y, value),
    do: {"enable endstops, y-axis", nil, format_bool(value)}

  def to_human(:movement_enable_endpoints_z, value),
    do: {"enable endstops, z-axis", nil, format_bool(value)}

  def to_human(:movement_invert_motor_x, value),
    do: {"invert motor, x-axis", nil, format_bool(value)}

  def to_human(:movement_invert_motor_y, value),
    do: {"invert motor, y-axis", nil, format_bool(value)}

  def to_human(:movement_invert_motor_z, value),
    do: {"invert motor, z-axis", nil, format_bool(value)}

  def to_human(:movement_secondary_motor_x, value),
    do: {"enable 2nd x motor", nil, format_bool(value)}

  def to_human(:movement_secondary_motor_invert_x, value),
    do: {"invert 2nd x motor", nil, format_bool(value)}

  def to_human(:movement_steps_acc_dec_x, value),
    do: {"accelerate for, x-axis", @steps, format_float(value)}

  def to_human(:movement_steps_acc_dec_y, value),
    do: {"accelerate for, y-axis", @steps, format_float(value)}

  def to_human(:movement_steps_acc_dec_z, value),
    do: {"accelerate for, z-axis", @steps, format_float(value)}

  def to_human(:movement_stop_at_home_x, value),
    do: {"stop at home, x-axis", nil, format_bool(value)}

  def to_human(:movement_stop_at_home_y, value),
    do: {"stop at home, y-axis", nil, format_bool(value)}

  def to_human(:movement_stop_at_home_z, value),
    do: {"stop at home, z-axis", nil, format_bool(value)}

  def to_human(:movement_home_up_x, value),
    do: {"negative coordinates only, x-axis", nil, format_bool(value)}

  def to_human(:movement_home_up_y, value),
    do: {"negative coordinates only, y-axis", nil, format_bool(value)}

  def to_human(:movement_home_up_z, value),
    do: {"negative coordinates only, z-axis", nil, format_bool(value)}

  def to_human(:movement_step_per_mm_x, value),
    do: {"steps per mm x-axis", @steps_per_mm, format_float(value)}

  def to_human(:movement_step_per_mm_y, value),
    do: {"steps per mm y-axis", @steps_per_mm, format_float(value)}

  def to_human(:movement_step_per_mm_z, value),
    do: {"steps per mm z-axis", @steps_per_mm, format_float(value)}

  def to_human(:movement_min_spd_x, value),
    do: {"minimum speed, x-axis", @steps_per_mm, format_float(value)}

  def to_human(:movement_min_spd_y, value),
    do: {"minimum speed, y-axis", @steps_per_mm, format_float(value)}

  def to_human(:movement_min_spd_z, value),
    do: {"minimum speed, z-axis", @steps_per_mm, format_float(value)}

  def to_human(:movement_home_spd_x, value),
    do: {"homing speed, x-axis", @steps_per_mm, format_float(value)}

  def to_human(:movement_home_spd_y, value),
    do: {"homing speed, y-axis", @steps_per_mm, format_float(value)}

  def to_human(:movement_home_spd_z, value),
    do: {"homing speed, z-axis", @steps_per_mm, format_float(value)}

  def to_human(:movement_max_spd_x, value),
    do: {"max speed, x-axis", @steps_per_mm, format_float(value)}

  def to_human(:movement_max_spd_y, value),
    do: {"max speed, y-axis", @steps_per_mm, format_float(value)}

  def to_human(:movement_max_spd_z, value),
    do: {"max speed, z-axis", @steps_per_mm, format_float(value)}

  def to_human(:movement_invert_2_endpoints_x, value),
    do: {"invert endstops, x-axis", nil, format_bool(value)}

  def to_human(:movement_invert_2_endpoints_y, value),
    do: {"invert endstops, y-axis", nil, format_bool(value)}

  def to_human(:movement_invert_2_endpoints_z, value),
    do: {"invert endstops, z-axis", nil, format_bool(value)}

  def to_human(:movement_motor_current_x, value),
    do: {"motor current, x-axis", @amps, format_float(value)}

  def to_human(:movement_motor_current_y, value),
    do: {"motor current, y-axis", @amps, format_float(value)}

  def to_human(:movement_motor_current_z, value),
    do: {"motor current, z-axis", @amps, format_float(value)}

  def to_human(:movement_stall_sensitivity_x, value),
    do: {"stall sensitivity, x-axis", nil, format_float(value)}

  def to_human(:movement_stall_sensitivity_y, value),
    do: {"stall sensitivity, y-axis", nil, format_float(value)}

  def to_human(:movement_stall_sensitivity_z, value),
    do: {"stall sensitivity, z-axis", nil, format_float(value)}

  def to_human(:encoder_enabled_x, value),
    do: {"enable encoders, x-axis", nil, format_bool(value)}

  def to_human(:encoder_enabled_y, value),
    do: {"enable encoders, y-axis", nil, format_bool(value)}

  def to_human(:encoder_enabled_z, value),
    do: {"enable encoders, z-axis", nil, format_bool(value)}

  def to_human(:encoder_type_x, value),
    do: {"encoder type, x-axis", nil, format_float(value)}

  def to_human(:encoder_type_y, value),
    do: {"encoder type, y-axis", nil, format_float(value)}

  def to_human(:encoder_type_z, value),
    do: {"encoder type, z-axis", nil, format_float(value)}

  def to_human(:encoder_missed_steps_max_x, value),
    do: {"max missed steps, x-axis", nil, format_float(value)}

  def to_human(:encoder_missed_steps_max_y, value),
    do: {"max missed steps, y-axis", nil, format_float(value)}

  def to_human(:encoder_missed_steps_max_z, value),
    do: {"max missed steps, z-axis", nil, format_float(value)}

  def to_human(:encoder_scaling_x, value),
    do: {"encoder scaling, x-axis", nil, format_float(value)}

  def to_human(:encoder_scaling_y, value),
    do: {"encoder scaling, y-axis", nil, format_float(value)}

  def to_human(:encoder_scaling_z, value),
    do: {"encoder scaling, z-axis", nil, format_float(value)}

  def to_human(:encoder_missed_steps_decay_x, value),
    do: {"encoder missed steps decay, x-axis", nil, format_float(value)}

  def to_human(:encoder_missed_steps_decay_y, value),
    do: {"encoder missed steps decay, y-axis", nil, format_float(value)}

  def to_human(:encoder_missed_steps_decay_z, value),
    do: {"encoder missed steps decay, z-axis", nil, format_float(value)}

  def to_human(:encoder_use_for_pos_x, value),
    do: {"use encoders for positioning, x-axis", nil, format_bool(value)}

  def to_human(:encoder_use_for_pos_y, value),
    do: {"use encoders for positioning, y-axis", nil, format_bool(value)}

  def to_human(:encoder_use_for_pos_z, value),
    do: {"use encoders for positioning, z-axis", nil, format_bool(value)}

  def to_human(:encoder_invert_x, value),
    do: {"invert encoders, x-axis", nil, format_bool(value)}

  def to_human(:encoder_invert_y, value),
    do: {"invert encoders, y-axis", nil, format_bool(value)}

  def to_human(:encoder_invert_z, value),
    do: {"invert encoders, z-axis", nil, format_bool(value)}

  def to_human(:movement_axis_nr_steps_x, value),
    do: {"axis length, x-axis", @steps, format_float(value)}

  def to_human(:movement_axis_nr_steps_y, value),
    do: {"axis length, y-axis", @steps, format_float(value)}

  def to_human(:movement_axis_nr_steps_z, value),
    do: {"axis length, z-axis", @steps, format_float(value)}

  def to_human(:movement_stop_at_max_x, value),
    do: {"stop at max, x-axis", nil, format_bool(value)}

  def to_human(:movement_stop_at_max_y, value),
    do: {"stop at max, y-axis", nil, format_bool(value)}

  def to_human(:movement_stop_at_max_z, value),
    do: {"stop at max, z-axis", nil, format_bool(value)}

  def to_human(:pin_guard_1_pin_nr, value),
    do: {"pin guard 1 pin number", nil, format_float(value)}

  def to_human(:pin_guard_1_time_out, value),
    do: {"pin guard 1 timeout", @seconds, format_float(value)}

  def to_human(:pin_guard_1_active_state, value),
    do: {"pin guard 1 safe state", nil, format_high_low_inverted(value)}

  def to_human(:pin_guard_2_pin_nr, value),
    do: {"pin guard 2 pin number", nil, format_float(value)}

  def to_human(:pin_guard_2_time_out, value),
    do: {"pin guard 2 timeout", @seconds, format_float(value)}

  def to_human(:pin_guard_2_active_state, value),
    do: {"pin guard 2 safe state", nil, format_high_low_inverted(value)}

  def to_human(:pin_guard_3_pin_nr, value),
    do: {"pin guard 3 pin number", nil, format_float(value)}

  def to_human(:pin_guard_3_time_out, value),
    do: {"pin guard 3 timeout", @seconds, format_float(value)}

  def to_human(:pin_guard_3_active_state, value),
    do: {"pin guard 3 safe state", nil, format_high_low_inverted(value)}

  def to_human(:pin_guard_4_pin_nr, value),
    do: {"pin guard 4 pin number", nil, format_float(value)}

  def to_human(:pin_guard_4_time_out, value),
    do: {"pin guard 4 timeout", @seconds, format_float(value)}

  def to_human(:pin_guard_4_active_state, value),
    do: {"pin guard 4 safe state", nil, format_high_low_inverted(value)}

  def to_human(:pin_guard_5_pin_nr, value),
    do: {"pin guard 5 pin number", nil, format_float(value)}

  def to_human(:pin_guard_5_time_out, value),
    do: {"pin guard 5 timeout", @seconds, format_float(value)}

  def to_human(:pin_guard_5_active_state, value),
    do: {"pin guard 5 safe state", nil, format_high_low_inverted(value)}

  def format_float(value) when is_integer(value) do
    format_float(value / 1)
  end

  def format_float(value) when is_float(value) do
    case :math.fmod(value, 1) do
      # value has no remainder
      rem when rem <= 0.0 -> :erlang.float_to_binary(value, decimals: 0)
      _ -> :erlang.float_to_binary(value, decimals: 1)
    end
  end

  def format_bool(val) when val == 1, do: true
  def format_bool(val) when val == 0, do: false

  def format_high_low_inverted(val) when val == 0, do: "HIGH"
  def format_high_low_inverted(val) when val == 1, do: "LOW"
end
