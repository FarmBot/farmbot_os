defmodule Gcode do
  @moduledoc """
    Im lazy and didn't want to parse yaml or write macros
  """

  def parse_code("G0") do  { :move_to_location_at_given_speed_for_axis } end
  def parse_code("G1" )do  { :move_to_location_on_a_straight_line } end
  def parse_code("G28") do { :move_home_all_axis } end
  def parse_code("F1" ) do { :dose_amount_of_water_using_time_in_millisecond } end
  def parse_code("F2" ) do { :dose_amount_of_water_using_flow_meter_that_measures_pulses } end
  def parse_code("F11") do { :home_x_axis } end
  def parse_code("F12") do { :home_y_axis } end
  def parse_code("F13") do { :home_z_axis } end
  def parse_code("F14") do { :calibrate_x_axis } end
  def parse_code("F15") do { :calibrate_y_axis } end
  def parse_code("F16") do { :calibrate_z_axis } end
  def parse_code("F21") do { :read_parameter } end
  def parse_code("F22") do { :write_parameter } end
  def parse_code("F23") do { :update_parameter_during_calibration } end
  def parse_code("F31") do { :read_status } end
  def parse_code("F32") do { :write_status } end
  def parse_code("F41") do { :set_a_value_on_an_arduino_pin } end
  def parse_code("F42") do { :read_a_value_from_an_arduino_pin } end
  def parse_code("F43") do { :set_the_mode_of_a_pin_in_arduino } end
  def parse_code("F44") do { :set_the_value_v_on_an_arduino_pin } end
  def parse_code("F51") do { :set_a_value_on_the_tool_mount_with_i2c } end
  def parse_code("F52") do { :read_value_from_the_tool_mount_with_i2c } end
  def parse_code("F61") do { :set_the_servo_on_the_pin_to_the_requested_angle } end
  def parse_code("F81") do { :report_end_stop } end
  def parse_code("F82") do { :report_current_position } end
  def parse_code("F83") do { :report_software_version } end
  def parse_code("E"  ) do { :emergency_stop } end
  def parse_code("R0" ) do { :idle } end
  def parse_code("R1" ) do { :received } end
  def parse_code("R2" ) do { :done } end
  def parse_code("R3" ) do { :error } end
  def parse_code("R4" ) do { :busy } end
  def parse_code("R00") do { :idle } end
  def parse_code("R01") do { :received } end
  def parse_code("R02") do { :done } end
  def parse_code("R03") do { :error } end
  def parse_code("R04") do { :busy } end
  def parse_code("R21 " <> params) do { :report_parameter_value, params } end
  def parse_code("R31") do { :report_status_value } end
  def parse_code("R41 " <> params) do { :report_pin_value, params } end
  def parse_code("R81 " <> params ) do { :reporting_end_stops, params } end
  def parse_code("R82 " <> position) do { :report_current_position, position } end
  def parse_code("R83") do { :report_software_version } end
  def parse_code("R99 " <> message) do { :debug_message, message } end
  def parse_code(code)  do {:unhandled_gcode, code} end

  def parse_param("0"  ) do :PARAM_VERSION end
  def parse_param("11" ) do :MOVEMENT_TIMEOUT_X end
  def parse_param("12" ) do :MOVEMENT_TIMEOUT_Y end
  def parse_param("13" ) do :MOVEMENT_TIMEOUT_Z end
  def parse_param("21" ) do :MOVEMENT_INVERT_ENDPOINTS_X end
  def parse_param("22" ) do :MOVEMENT_INVERT_ENDPOINTS_Y end
  def parse_param("23" ) do :MOVEMENT_INVERT_ENDPOINTS_Z end
  def parse_param("31" ) do :MOVEMENT_INVERT_MOTOR_X end
  def parse_param("32" ) do :MOVEMENT_INVERT_MOTOR_Y end
  def parse_param("33" ) do :MOVEMENT_INVERT_MOTOR_Z end
  def parse_param("41" ) do :MOVEMENT_STEPS_ACC_DEC_X end
  def parse_param("42" ) do :MOVEMENT_STEPS_ACC_DEC_Y end
  def parse_param("43" ) do :MOVEMENT_STEPS_ACC_DEC_Z end
  def parse_param("51" ) do :MOVEMENT_HOME_UP_X end
  def parse_param("52" ) do :MOVEMENT_HOME_UP_Y end
  def parse_param("53" ) do :MOVEMENT_HOME_UP_Z end
  def parse_param("61" ) do :MOVEMENT_MIN_SPD_X end
  def parse_param("62" ) do :MOVEMENT_MIN_SPD_Y end
  def parse_param("63" ) do :MOVEMENT_MIN_SPD_Z end
  def parse_param("71" ) do :MOVEMENT_MAX_SPD_X end
  def parse_param("72" ) do :MOVEMENT_MAX_SPD_Y end
  def parse_param("73" ) do :MOVEMENT_MAX_SPD_Z end
  def parse_param("101") do :ENCODER_ENABLED_X end
  def parse_param("102") do :ENCODER_ENABLED_Y end
  def parse_param("103") do :ENCODER_ENABLED_Z end
  def parse_param("111") do :ENCODER_MISSED_STEPS_MAX_X end
  def parse_param("112") do :ENCODER_MISSED_STEPS_MAX_Y end
  def parse_param("113") do :ENCODER_MISSED_STEPS_MAX_Z end
  def parse_param("121") do :ENCODER_MISSED_STEPS_DECAY_X end
  def parse_param("122") do :ENCODER_MISSED_STEPS_DECAY_Y end
  def parse_param("123") do :ENCODER_MISSED_STEPS_DECAY_Z end
  def parse_param("141") do :MOVEMENT_AXIS_NR_STEPS_X end
  def parse_param("142") do :MOVEMENT_AXIS_NR_STEPS_Y end
  def parse_param("143") do :MOVEMENT_AXIS_NR_STEPS_Z end
  def parse_param("201") do :PIN_GUARD_1_PIN_NR end
  def parse_param("202") do :PIN_GUARD_1_TIME_OUT end
  def parse_param("203") do :PIN_GUARD_1_ACTIVE_STATE end
  def parse_param("205") do :PIN_GUARD_2_PIN_NR end
  def parse_param("206") do :PIN_GUARD_2_TIME_OUT end
  def parse_param("207") do :PIN_GUARD_2_ACTIVE_STATE end
  def parse_param("211") do :PIN_GUARD_3_PIN_NR end
  def parse_param("212") do :PIN_GUARD_3_TIME_OUT end
  def parse_param("213") do :PIN_GUARD_3_ACTIVE_STATE end
  def parse_param("215") do :PIN_GUARD_4_PIN_NR end
  def parse_param("216") do :PIN_GUARD_4_TIME_OUT end
  def parse_param("217") do :PIN_GUARD_4_ACTIVE_STATE end
  def parse_param("221") do :PIN_GUARD_5_PIN_NR end
  def parse_param("222") do :PIN_GUARD_5_TIME_OUT end
  def parse_param("223") do :PIN_GUARD_5_ACTIVE_STATE end
  def parse_param(param) when is_integer(param) do
    parse_param("#{param}")
  end

  def parse_param(:PARAM_VERSION) do 0 end
  def parse_param(:MOVEMENT_TIMEOUT_X) do 11 end
  def parse_param(:MOVEMENT_TIMEOUT_Y) do 12 end
  def parse_param(:MOVEMENT_TIMEOUT_Z) do 13 end
  def parse_param(:MOVEMENT_INVERT_ENDPOINTS_X) do 21 end
  def parse_param(:MOVEMENT_INVERT_ENDPOINTS_Y) do 22 end
  def parse_param(:MOVEMENT_INVERT_ENDPOINTS_Z) do 23 end
  def parse_param(:MOVEMENT_INVERT_MOTOR_X) do 31 end
  def parse_param(:MOVEMENT_INVERT_MOTOR_Y) do 32 end
  def parse_param(:MOVEMENT_INVERT_MOTOR_Z) do 33 end
  def parse_param(:MOVEMENT_STEPS_ACC_DEC_X) do 41 end
  def parse_param(:MOVEMENT_STEPS_ACC_DEC_Y) do 42 end
  def parse_param(:MOVEMENT_STEPS_ACC_DEC_Z) do 43 end
  def parse_param(:MOVEMENT_HOME_UP_X) do 51 end
  def parse_param(:MOVEMENT_HOME_UP_Y) do 52 end
  def parse_param(:MOVEMENT_HOME_UP_Z) do 53 end
  def parse_param(:MOVEMENT_MIN_SPD_X) do 61 end
  def parse_param(:MOVEMENT_MIN_SPD_Y) do 62 end
  def parse_param(:MOVEMENT_MIN_SPD_Z) do 63 end
  def parse_param(:MOVEMENT_MAX_SPD_X) do 71 end
  def parse_param(:MOVEMENT_MAX_SPD_Y) do 72 end
  def parse_param(:MOVEMENT_MAX_SPD_Z) do 73 end
  def parse_param(:ENCODER_ENABLED_X) do 101 end
  def parse_param(:ENCODER_ENABLED_Y) do 102 end
  def parse_param(:ENCODER_ENABLED_Z) do 103 end
  def parse_param(:ENCODER_MISSED_STEPS_MAX_X) do 111 end
  def parse_param(:ENCODER_MISSED_STEPS_MAX_Y) do 112 end
  def parse_param(:ENCODER_MISSED_STEPS_MAX_Z) do 113 end
  def parse_param(:ENCODER_MISSED_STEPS_DECAY_X) do 121 end
  def parse_param(:ENCODER_MISSED_STEPS_DECAY_Y) do 122 end
  def parse_param(:ENCODER_MISSED_STEPS_DECAY_Z) do 123 end
  def parse_param(:MOVEMENT_AXIS_NR_STEPS_X) do 141 end
  def parse_param(:MOVEMENT_AXIS_NR_STEPS_Y) do 142 end
  def parse_param(:MOVEMENT_AXIS_NR_STEPS_Z) do 143 end
  def parse_param(:PIN_GUARD_1_PIN_NR) do 201 end
  def parse_param(:PIN_GUARD_1_TIME_OUT) do 202 end
  def parse_param(:PIN_GUARD_1_ACTIVE_STATE) do 203 end
  def parse_param(:PIN_GUARD_2_PIN_NR) do 205 end
  def parse_param(:PIN_GUARD_2_TIME_OUT) do 206 end
  def parse_param(:PIN_GUARD_2_ACTIVE_STATE) do 207 end
  def parse_param(:PIN_GUARD_3_PIN_NR) do 211 end
  def parse_param(:PIN_GUARD_3_TIME_OUT) do 212 end
  def parse_param(:PIN_GUARD_3_ACTIVE_STATE) do 213 end
  def parse_param(:PIN_GUARD_4_PIN_NR) do 215 end
  def parse_param(:PIN_GUARD_4_TIME_OUT) do 216 end
  def parse_param(:PIN_GUARD_4_ACTIVE_STATE) do 217 end
  def parse_param(:PIN_GUARD_5_PIN_NR) do 221 end
  def parse_param(:PIN_GUARD_5_TIME_OUT) do 222 end
  def parse_param(:PIN_GUARD_5_ACTIVE_STATE) do 223 end
  def parse_param(param) when is_bitstring(param) do
    String.Casing.upcase(param)
    |> String.to_atom
    |> parse_param
  end
  def parse_param(_) do nil end
end
