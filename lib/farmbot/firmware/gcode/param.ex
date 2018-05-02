defmodule Farmbot.Firmware.Gcode.Param do
  @moduledoc "Firmware paramaters."

  @doc "Turn a number into a param, or a param into a number."
  @spec parse_param(integer | t) :: t | integer
  def parse_param(0), do: :param_version
  def parse_param(1), do: :param_test
  def parse_param(2), do: :param_config_ok
  def parse_param(3), do: :param_use_eeprom
  def parse_param(4), do: :param_e_stop_on_mov_err
  def parse_param(5), do: :param_mov_nr_retry
  def parse_param(11), do: :movement_timeout_x
  def parse_param(12), do: :movement_timeout_y
  def parse_param(13), do: :movement_timeout_z
  def parse_param(15), do: :movement_keep_active_x
  def parse_param(16), do: :movement_keep_active_y
  def parse_param(17), do: :movement_keep_active_z
  def parse_param(18), do: :movement_home_at_boot_x
  def parse_param(19), do: :movement_home_at_boot_y
  def parse_param(20), do: :movement_home_at_boot_z
  def parse_param(21), do: :movement_invert_endpoints_x
  def parse_param(22), do: :movement_invert_endpoints_y
  def parse_param(23), do: :movement_invert_endpoints_z
  def parse_param(25), do: :movement_enable_endpoints_x
  def parse_param(26), do: :movement_enable_endpoints_y
  def parse_param(27), do: :movement_enable_endpoints_z
  def parse_param(31), do: :movement_invert_motor_x
  def parse_param(32), do: :movement_invert_motor_y
  def parse_param(33), do: :movement_invert_motor_z
  def parse_param(36), do: :movement_secondary_motor_x
  def parse_param(37), do: :movement_secondary_motor_invert_x
  def parse_param(41), do: :movement_steps_acc_dec_x
  def parse_param(42), do: :movement_steps_acc_dec_y
  def parse_param(43), do: :movement_steps_acc_dec_z
  def parse_param(45), do: :movement_stop_at_home_x
  def parse_param(46), do: :movement_stop_at_home_y
  def parse_param(47), do: :movement_stop_at_home_z
  def parse_param(51), do: :movement_home_up_x
  def parse_param(52), do: :movement_home_up_y
  def parse_param(53), do: :movement_home_up_z
  def parse_param(55), do: :movement_step_per_mm_x
  def parse_param(56), do: :movement_step_per_mm_y
  def parse_param(57), do: :movement_step_per_mm_z
  def parse_param(61), do: :movement_min_spd_x
  def parse_param(62), do: :movement_min_spd_y
  def parse_param(63), do: :movement_min_spd_z
  def parse_param(65), do: :movement_home_spd_x
  def parse_param(66), do: :movement_home_spd_y
  def parse_param(67), do: :movement_home_spd_z
  def parse_param(71), do: :movement_max_spd_x
  def parse_param(72), do: :movement_max_spd_y
  def parse_param(73), do: :movement_max_spd_z
  def parse_param(75), do: :movement_invert_2_endpoints_x
  def parse_param(76), do: :movement_invert_2_endpoints_y
  def parse_param(77), do: :movement_invert_2_endpoints_z
  def parse_param(101), do: :encoder_enabled_x
  def parse_param(102), do: :encoder_enabled_y
  def parse_param(103), do: :encoder_enabled_z
  def parse_param(105), do: :encoder_type_x
  def parse_param(106), do: :encoder_type_y
  def parse_param(107), do: :encoder_type_z
  def parse_param(111), do: :encoder_missed_steps_max_x
  def parse_param(112), do: :encoder_missed_steps_max_y
  def parse_param(113), do: :encoder_missed_steps_max_z
  def parse_param(115), do: :encoder_scaling_x
  def parse_param(116), do: :encoder_scaling_y
  def parse_param(117), do: :encoder_scaling_z
  def parse_param(121), do: :encoder_missed_steps_decay_x
  def parse_param(122), do: :encoder_missed_steps_decay_y
  def parse_param(123), do: :encoder_missed_steps_decay_z
  def parse_param(125), do: :encoder_use_for_pos_x
  def parse_param(126), do: :encoder_use_for_pos_y
  def parse_param(127), do: :encoder_use_for_pos_z
  def parse_param(131), do: :encoder_invert_x
  def parse_param(132), do: :encoder_invert_y
  def parse_param(133), do: :encoder_invert_z
  def parse_param(141), do: :movement_axis_nr_steps_x
  def parse_param(142), do: :movement_axis_nr_steps_y
  def parse_param(143), do: :movement_axis_nr_steps_z
  def parse_param(145), do: :movement_stop_at_max_x
  def parse_param(146), do: :movement_stop_at_max_y
  def parse_param(147), do: :movement_stop_at_max_z
  def parse_param(201), do: :pin_guard_1_pin_nr
  def parse_param(202), do: :pin_guard_1_time_out
  def parse_param(203), do: :pin_guard_1_active_state
  def parse_param(205), do: :pin_guard_2_pin_nr
  def parse_param(206), do: :pin_guard_2_time_out
  def parse_param(207), do: :pin_guard_2_active_state
  def parse_param(211), do: :pin_guard_3_pin_nr
  def parse_param(212), do: :pin_guard_3_time_out
  def parse_param(213), do: :pin_guard_3_active_state
  def parse_param(215), do: :pin_guard_4_pin_nr
  def parse_param(216), do: :pin_guard_4_time_out
  def parse_param(217), do: :pin_guard_4_active_state
  def parse_param(221), do: :pin_guard_5_pin_nr
  def parse_param(222), do: :pin_guard_5_time_out
  def parse_param(223), do: :pin_guard_5_active_state

  def parse_param(:param_version), do: 0
  def parse_param(:param_test), do: 1
  def parse_param(:param_config_ok), do: 2
  def parse_param(:param_use_eeprom), do: 3
  def parse_param(:param_e_stop_on_mov_err), do: 4
  def parse_param(:param_mov_nr_retry), do: 5
  def parse_param(:movement_timeout_x), do: 11
  def parse_param(:movement_timeout_y), do: 12
  def parse_param(:movement_timeout_z), do: 13
  def parse_param(:movement_keep_active_x), do: 15
  def parse_param(:movement_keep_active_y), do: 16
  def parse_param(:movement_keep_active_z), do: 17
  def parse_param(:movement_home_at_boot_x), do: 18
  def parse_param(:movement_home_at_boot_y), do: 19
  def parse_param(:movement_home_at_boot_z), do: 20
  def parse_param(:movement_invert_endpoints_x), do: 21
  def parse_param(:movement_invert_endpoints_y), do: 22
  def parse_param(:movement_invert_endpoints_z), do: 23
  def parse_param(:movement_enable_endpoints_x), do: 25
  def parse_param(:movement_enable_endpoints_y), do: 26
  def parse_param(:movement_enable_endpoints_z), do: 27
  def parse_param(:movement_invert_motor_x), do: 31
  def parse_param(:movement_invert_motor_y), do: 32
  def parse_param(:movement_invert_motor_z), do: 33
  def parse_param(:movement_secondary_motor_x), do: 36
  def parse_param(:movement_secondary_motor_invert_x), do: 37
  def parse_param(:movement_steps_acc_dec_x), do: 41
  def parse_param(:movement_steps_acc_dec_y), do: 42
  def parse_param(:movement_steps_acc_dec_z), do: 43
  def parse_param(:movement_stop_at_home_x), do: 45
  def parse_param(:movement_stop_at_home_y), do: 46
  def parse_param(:movement_stop_at_home_z), do: 47
  def parse_param(:movement_home_up_x), do: 51
  def parse_param(:movement_home_up_y), do: 52
  def parse_param(:movement_home_up_z), do: 53
  def parse_param(:movement_step_per_mm_x), do: 55
  def parse_param(:movement_step_per_mm_y), do: 56
  def parse_param(:movement_step_per_mm_z), do: 57
  def parse_param(:movement_min_spd_x), do: 61
  def parse_param(:movement_min_spd_y), do: 62
  def parse_param(:movement_min_spd_z), do: 63
  def parse_param(:movement_home_spd_x), do: 65
  def parse_param(:movement_home_spd_y), do: 66
  def parse_param(:movement_home_spd_z), do: 67
  def parse_param(:movement_max_spd_x), do: 71
  def parse_param(:movement_max_spd_y), do: 72
  def parse_param(:movement_max_spd_z), do: 73
  def parse_param(:movement_invert_2_endpoints_x), do: 75
  def parse_param(:movement_invert_2_endpoints_y), do: 76
  def parse_param(:movement_invert_2_endpoints_z), do: 77
  def parse_param(:encoder_enabled_x), do: 101
  def parse_param(:encoder_enabled_y), do: 102
  def parse_param(:encoder_enabled_z), do: 103
  def parse_param(:encoder_type_x), do: 105
  def parse_param(:encoder_type_y), do: 106
  def parse_param(:encoder_type_z), do: 107
  def parse_param(:encoder_missed_steps_max_x), do: 111
  def parse_param(:encoder_missed_steps_max_y), do: 112
  def parse_param(:encoder_missed_steps_max_z), do: 113
  def parse_param(:encoder_scaling_x), do: 115
  def parse_param(:encoder_scaling_y), do: 116
  def parse_param(:encoder_scaling_z), do: 117
  def parse_param(:encoder_missed_steps_decay_x), do: 121
  def parse_param(:encoder_missed_steps_decay_y), do: 122
  def parse_param(:encoder_missed_steps_decay_z), do: 123
  def parse_param(:encoder_use_for_pos_x), do: 125
  def parse_param(:encoder_use_for_pos_y), do: 126
  def parse_param(:encoder_use_for_pos_z), do: 127
  def parse_param(:encoder_invert_x), do: 131
  def parse_param(:encoder_invert_y), do: 132
  def parse_param(:encoder_invert_z), do: 133
  def parse_param(:movement_axis_nr_steps_x), do: 141
  def parse_param(:movement_axis_nr_steps_y), do: 142
  def parse_param(:movement_axis_nr_steps_z), do: 143
  def parse_param(:movement_stop_at_max_x), do: 145
  def parse_param(:movement_stop_at_max_y), do: 146
  def parse_param(:movement_stop_at_max_z), do: 147
  def parse_param(:pin_guard_1_pin_nr), do: 201
  def parse_param(:pin_guard_1_time_out), do: 202
  def parse_param(:pin_guard_1_active_state), do: 203
  def parse_param(:pin_guard_2_pin_nr), do: 205
  def parse_param(:pin_guard_2_time_out), do: 206
  def parse_param(:pin_guard_2_active_state), do: 207
  def parse_param(:pin_guard_3_pin_nr), do: 211
  def parse_param(:pin_guard_3_time_out), do: 212
  def parse_param(:pin_guard_3_active_state), do: 213
  def parse_param(:pin_guard_4_pin_nr), do: 215
  def parse_param(:pin_guard_4_time_out), do: 216
  def parse_param(:pin_guard_4_active_state), do: 217
  def parse_param(:pin_guard_5_pin_nr), do: 221
  def parse_param(:pin_guard_5_time_out), do: 222
  def parse_param(:pin_guard_5_active_state), do: 223

  @typedoc "Human readable param name."
  @type t :: :param_config_ok |
  :param_use_eeprom |
  :param_e_stop_on_mov_err |
  :param_mov_nr_retry |
  :movement_timeout_x |
  :movement_timeout_y |
  :movement_timeout_z |
  :movement_keep_active_x |
  :movement_keep_active_y |
  :movement_keep_active_z |
  :movement_home_at_boot_x |
  :movement_home_at_boot_y |
  :movement_home_at_boot_z |
  :movement_invert_endpoints_x |
  :movement_invert_endpoints_y |
  :movement_invert_endpoints_z |
  :movement_enable_endpoints_x |
  :movement_enable_endpoints_y |
  :movement_enable_endpoints_z |
  :movement_invert_motor_x |
  :movement_invert_motor_y |
  :movement_invert_motor_z |
  :movement_secondary_motor_x |
  :movement_secondary_motor_invert_x |
  :movement_steps_acc_dec_x |
  :movement_steps_acc_dec_y |
  :movement_steps_acc_dec_z |
  :movement_stop_at_home_x |
  :movement_stop_at_home_y |
  :movement_stop_at_home_z |
  :movement_home_up_x |
  :movement_home_up_y |
  :movement_home_up_z |
  :movement_step_per_mm_x |
  :movement_step_per_mm_y |
  :movement_step_per_mm_z |
  :movement_min_spd_x |
  :movement_min_spd_y |
  :movement_min_spd_z |
  :movement_home_spd_x |
  :movement_home_spd_y |
  :movement_home_spd_z |
  :movement_max_spd_x |
  :movement_max_spd_y |
  :movement_max_spd_z |
  :movement_invert_2_endpoints_x |
  :movement_invert_2_endpoints_y |
  :movement_invert_2_endpoints_z |
  :encoder_enabled_x |
  :encoder_enabled_y |
  :encoder_enabled_z |
  :encoder_type_x |
  :encoder_type_y |
  :encoder_type_z |
  :encoder_missed_steps_max_x |
  :encoder_missed_steps_max_y |
  :encoder_missed_steps_max_z |
  :encoder_scaling_x |
  :encoder_scaling_y |
  :encoder_scaling_z |
  :encoder_missed_steps_decay_x |
  :encoder_missed_steps_decay_y |
  :encoder_missed_steps_decay_z |
  :encoder_use_for_pos_x |
  :encoder_use_for_pos_y |
  :encoder_use_for_pos_z |
  :encoder_invert_x |
  :encoder_invert_y |
  :encoder_invert_z |
  :movement_axis_nr_steps_x |
  :movement_axis_nr_steps_y |
  :movement_axis_nr_steps_z |
  :movement_stop_at_max_x |
  :movement_stop_at_max_y |
  :movement_stop_at_max_z |
  :pin_guard_1_pin_nr |
  :pin_guard_1_time_out |
  :pin_guard_1_active_state |
  :pin_guard_2_pin_nr |
  :pin_guard_2_time_out |
  :pin_guard_2_active_state |
  :pin_guard_3_pin_nr |
  :pin_guard_3_time_out |
  :pin_guard_3_active_state |
  :pin_guard_4_pin_nr |
  :pin_guard_4_time_out |
  :pin_guard_4_active_state |
  :pin_guard_5_pin_nr |
  :pin_guard_5_time_out |
  :pin_guard_5_active_state

end
