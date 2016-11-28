defmodule Farmbot.Serial.Gcode.Parser do
  @moduledoc """
    Parses farmbot_arduino_firmware G-Codes.
  """

  @spec parse_code(binary) :: tuple
  def parse_code("R0" ) do { :idle, qtag } end
  def parse_code("R0 Q" <>tag) do { :idle, tag } end
  def parse_code("R1" ) do { :received, qtag } end
  def parse_code("R1 Q" <>tag) do { :received, tag } end
  def parse_code("R2" ) do { :done, qtag } end
  def parse_code("R2 Q" <>tag) do { :done, tag } end
  def parse_code("R3" ) do { :error, qtag } end
  def parse_code("R3 Q" <>tag) do { :error, tag } end
  def parse_code("R4" ) do { :busy, qtag } end
  def parse_code("R4 Q" <>tag) do { :busy, tag } end
  def parse_code("R00") do { :idle, qtag } end
  def parse_code("R00 Q"<>tag) do { :idle, tag } end
  def parse_code("R01") do { :received, qtag } end
  def parse_code("R01 Q"<>tag) do { :received, tag } end
  def parse_code("R02") do { :done, qtag } end
  def parse_code("R02 Q"<>tag) do { :done, tag } end
  def parse_code("R03") do { :error, qtag } end
  def parse_code("R03 Q"<>tag) do { :error, tag } end
  def parse_code("R04") do { :busy, qtag } end
  def parse_code("R04 Q"<>tag) do { :busy, tag } end

  def parse_code("R21 " <> params), do: parse_pvq(params, :report_parameter_value)
  def parse_code("R31 " <> params), do: parse_pvq(params, :report_status_value)
  def parse_code("R41 " <> params), do: parse_pvq(params, :report_pin_value)
  def parse_code("R81 " <> params), do: parse_end_stops(params)
  def parse_code("R82 " <> position), do: parse_report_current_position(position)

  def parse_code("R83") do { :report_software_version } end
  def parse_code("R99 " <> message) do { :debug_message, message } end
  def parse_code(code)  do {:unhandled_gcode, code} end

  @doc """
    Parses R82 codes
    Example:
      iex> Gcode.parse_report_current_position("X34 Y756 Z23")
      {:report_current_position, 34, 756, 23, "0"}
  """
  @spec parse_report_current_position(binary)
  :: {:report_current_position, String.t, String.t, String.t, String.t}
  def parse_report_current_position(position) when is_bitstring(position) do
    case String.split(position, " ") do
      ["X"<>x, "Y"<>y, "Z"<>z] ->
        { :report_current_position,
          String.to_integer(x),
          String.to_integer(y),
          String.to_integer(z), qtag }
      ["X"<>x, "Y"<>y, "Z"<>z, "Q"<>tag] ->
        { :report_current_position,
          String.to_integer(x),
          String.to_integer(y),
          String.to_integer(z), tag }
    end
  end

  @doc """
    Parses End Stops. I don't think we actually use these yet.
    Example:
      iex> Gcode.parse_end_stops("XA1 XB1 YA0 YB1 ZA0 ZB1 Q123")
      {:reporting_end_stops, "1", "1", "0", "1", "0", "1", "123"}
  """
  @spec parse_end_stops(binary)
  :: {:reporting_end_stops,
      String.t,
      String.t,
      String.t,
      String.t,
      String.t,
      String.t,
      String.t}
  def parse_end_stops(
    <<
      "XA", xa :: size(8), 32,
      "XB", xb :: size(8), 32,
      "YA", ya :: size(8), 32,
      "YB", yb :: size(8), 32,
      "ZA", za :: size(8), 32,
      "ZB", zb :: size(8), 32,
      "Q", tag :: binary
    >>), do: {:reporting_end_stops, xa, xb, ya, yb, za, zb, tag}

  def parse_end_stops(
    <<
      "XA", xa :: size(8), 32,
      "XB", xb :: size(8), 32,
      "YA", ya :: size(8), 32,
      "YB", yb :: size(8), 32,
      "ZA", za :: size(8), 32,
      "ZB", zb :: size(8)
    >>), do: {:reporting_end_stops, xa, xb, ya, yb, za, zb, qtag}

  @doc """
    common function for report_(something)_value from gcode.
    Example:
      iex> Gcode.parse_pvq("P20 V100", :report_parameter_value)
      {:report_parameter_value, "20" ,"100", "0"}

    Example:
      iex> Gcode.parse_pvq("P20 V100 Q12", :report_parameter_value)
      {:report_parameter_value, "20" ,"100", "12"}
  """
  @spec parse_pvq(binary, :report_parameter_value)
  :: {:report_parameter_value, atom, integer, String.t}
  def parse_pvq(params, :report_parameter_value)
  when is_bitstring(params) do
    case String.split(params, " ") do
      [p, v] ->
        [_, rp] = String.split(p, "P")
        [_, rv] = String.split(v, "V")
        {:report_parameter_value, parse_param(rp), String.to_integer(rv), qtag}
      [p, v, q] ->
        [_, rp] = String.split(p, "P")
        [_, rv] = String.split(v, "V")
        [_, rq] = String.split(q, "Q")
        {:report_parameter_value, parse_param(rp), String.to_integer(rv), rq}
    end
  end

  def parse_pvq(params, human_readable_param_name)
  when is_bitstring(params)
   and is_atom(human_readable_param_name) do
    case String.split(params, " ") do
      [p, v] ->
        [_, rp] = String.split(p, "P")
        [_, rv] = String.split(v, "V")
        {human_readable_param_name, String.to_integer(rp), String.to_integer(rv), qtag}
      [p, v, q] ->
        [_, rp] = String.split(p, "P")
        [_, rv] = String.split(v, "V")
        [_, rq] = String.split(q, "Q")
        {human_readable_param_name, String.to_integer(rp), String.to_integer(rv), rq}
    end
  end

  @doc """
    Parses farmbot_arduino_firmware params.
    If we want the name of param "0"\n
    Example:
      iex> Gcode.parse_param("0")
      :param_version

    Example:
      iex> Gcode.parse_param(0)
      :param_version

    If we want the integer of param :param_version\n
    Example:
      iex> Gcode.parse_param(:param_version)
      0

    Example:
      iex> Gcode.parse_param("param_version")
      0
  """
  @spec parse_param(binary | integer) :: atom | nil
  def parse_param("0"  ) do :param_version end
  def parse_param("11" ) do :movement_timeout_x end
  def parse_param("12" ) do :movement_timeout_y end
  def parse_param("13" ) do :movement_timeout_z end
  def parse_param("21" ) do :movement_invert_endpoints_x end
  def parse_param("22" ) do :movement_invert_endpoints_y end
  def parse_param("23" ) do :movement_invert_endpoints_z end
  def parse_param("31" ) do :movement_invert_motor_x end
  def parse_param("32" ) do :movement_invert_motor_y end
  def parse_param("33" ) do :movement_invert_motor_z end
  def parse_param("41" ) do :movement_steps_acc_dec_x end
  def parse_param("42" ) do :movement_steps_acc_dec_y end
  def parse_param("43" ) do :movement_steps_acc_dec_z end
  def parse_param("51" ) do :movement_home_up_x end
  def parse_param("52" ) do :movement_home_up_y end
  def parse_param("53" ) do :movement_home_up_z end
  def parse_param("61" ) do :movement_min_spd_x end
  def parse_param("62" ) do :movement_min_spd_y end
  def parse_param("63" ) do :movement_min_spd_z end
  def parse_param("71" ) do :movement_max_spd_x end
  def parse_param("72" ) do :movement_max_spd_y end
  def parse_param("73" ) do :movement_max_spd_z end
  def parse_param("101") do :encoder_enabled_x end
  def parse_param("102") do :encoder_enabled_y end
  def parse_param("103") do :encoder_enabled_z end
  def parse_param("111") do :encoder_missed_steps_max_x end
  def parse_param("112") do :encoder_missed_steps_max_y end
  def parse_param("113") do :encoder_missed_steps_max_z end
  def parse_param("121") do :encoder_missed_steps_decay_x end
  def parse_param("122") do :encoder_missed_steps_decay_y end
  def parse_param("123") do :encoder_missed_steps_decay_z end
  def parse_param("141") do :movement_axis_nr_steps_x end
  def parse_param("142") do :movement_axis_nr_steps_y end
  def parse_param("143") do :movement_axis_nr_steps_z end
  def parse_param("201") do :pin_guard_1_pin_nr end
  def parse_param("202") do :pin_guard_1_pin_time_out end
  def parse_param("203") do :pin_guard_1_active_state end
  def parse_param("205") do :pin_guard_2_pin_nr end
  def parse_param("206") do :pin_guard_2_pin_time_out end
  def parse_param("207") do :pin_guard_2_active_state end
  def parse_param("211") do :pin_guard_3_pin_nr end
  def parse_param("212") do :pin_guard_3_pin_time_out end
  def parse_param("213") do :pin_guard_3_active_state end
  def parse_param("215") do :pin_guard_4_pin_nr end
  def parse_param("216") do :pin_guard_4_pin_time_out end
  def parse_param("217") do :pin_guard_4_active_state end
  def parse_param("221") do :pin_guard_5_pin_nr end
  def parse_param("222") do :pin_guard_5_time_out end
  def parse_param("223") do :pin_guard_5_active_state end
  def parse_param(param) when is_integer(param), do: parse_param("#{param}")

  @spec parse_param(atom) :: integer | nil
  def parse_param(:param_version) do 0 end
  def parse_param(:movement_timeout_x) do 11 end
  def parse_param(:movement_timeout_y) do 12 end
  def parse_param(:movement_timeout_z) do 13 end
  def parse_param(:movement_invert_endpoints_x) do 21 end
  def parse_param(:movement_invert_endpoints_y) do 22 end
  def parse_param(:movement_invert_endpoints_z) do 23 end
  def parse_param(:movement_invert_motor_x) do 31 end
  def parse_param(:movement_invert_motor_y) do 32 end
  def parse_param(:movement_invert_motor_z) do 33 end
  def parse_param(:movement_steps_acc_dec_x) do 41 end
  def parse_param(:movement_steps_acc_dec_y) do 42 end
  def parse_param(:movement_steps_acc_dec_z) do 43 end
  def parse_param(:movement_home_up_x) do 51 end
  def parse_param(:movement_home_up_y) do 52 end
  def parse_param(:movement_home_up_z) do 53 end
  def parse_param(:movement_min_spd_x) do 61 end
  def parse_param(:movement_min_spd_y) do 62 end
  def parse_param(:movement_min_spd_z) do 63 end
  def parse_param(:movement_max_spd_x) do 71 end
  def parse_param(:movement_max_spd_y) do 72 end
  def parse_param(:movement_max_spd_z) do 73 end
  def parse_param(:encoder_enabled_x) do 101 end
  def parse_param(:encoder_enabled_y) do 102 end
  def parse_param(:encoder_enabled_z) do 103 end
  def parse_param(:encoder_missed_steps_max_x) do 111 end
  def parse_param(:encoder_missed_steps_max_y) do 112 end
  def parse_param(:encoder_missed_steps_max_z) do 113 end
  def parse_param(:encoder_missed_steps_decay_x) do 121 end
  def parse_param(:encoder_missed_steps_decay_y) do 122 end
  def parse_param(:encoder_missed_steps_decay_z) do 123 end
  def parse_param(:movement_axis_nr_steps_x) do 141 end
  def parse_param(:movement_axis_nr_steps_y) do 142 end
  def parse_param(:movement_axis_nr_steps_z) do 143 end
  def parse_param(:pin_guard_1_pin_nr) do 201 end
  def parse_param(:pin_guard_1_pin_time_out) do 202 end
  def parse_param(:pin_guard_1_active_state) do 203 end
  def parse_param(:pin_guard_2_pin_nr) do 205 end
  def parse_param(:pin_guard_2_pin_time_out) do 206 end
  def parse_param(:pin_guard_2_active_state) do 207 end
  def parse_param(:pin_guard_3_pin_nr) do 211 end
  def parse_param(:pin_guard_3_pin_time_out) do 212 end
  def parse_param(:pin_guard_3_active_state) do 213 end
  def parse_param(:pin_guard_4_pin_nr) do 215 end
  def parse_param(:pin_guard_4_pin_time_out) do 216 end
  def parse_param(:pin_guard_4_active_state) do 217 end
  def parse_param(:pin_guard_5_pin_nr) do 221 end
  def parse_param(:pin_guard_5_time_out) do 222 end
  def parse_param(:pin_guard_5_active_state) do 223 end
  def parse_param(param_string) when is_bitstring(param_string) do
    String.to_atom(param_string) |> parse_param
  end
  def parse_param(_), do: nil

  @spec qtag :: String.t
  defp qtag, do: "0"
end
