defmodule Farmbot.Serial.Gcode.Parser do
  @moduledoc """
    Parses farmbot_arduino_firmware G-Codes.
  """

  require Logger

  @spec parse_code(binary) :: {binary, tuple}

  def parse_code("R00 Q" <> tag), do: {tag, :idle}
  def parse_code("R01 Q" <> tag), do: {tag, :received}
  def parse_code("R02 Q" <> tag), do: {tag, :done}
  def parse_code("R03 Q" <> tag), do: {tag, :error}
  def parse_code("R04 Q" <> tag), do: {tag, :busy}

  def parse_code("R05" <> _r), do: {nil, :dont_handle_me} # Dont care about this.
  def parse_code("R06 " <> r), do: parse_report_calibration(r)

  def parse_code("R21 " <> params), do: parse_pvq(params, :report_parameter_value)
  def parse_code("R31 " <> params), do: parse_pvq(params, :report_status_value)
  def parse_code("R41 " <> params), do: parse_pvq(params, :report_pin_value)
  def parse_code("R81 " <> params), do: parse_end_stops(params)
  def parse_code("R82 " <> params), do: parse_report_current_position(params)
  def parse_code("R83 " <> v), do: parse_version(v)
  def parse_code("R99 " <> message) do {nil, {:debug_message, message}} end
  def parse_code("Command" <> _), do: {nil, :dont_handle_me} # I think this is a bug
  def parse_code(code)  do {:unhandled_gcode, code} end

  @spec parse_report_calibration(binary)
    :: {binary, {:report_calibration, binary, binary}}
  defp parse_report_calibration(r) do
    [axis_and_status | [q]] = String.split(r, " Q")
    <<a :: size(8), b :: size(8)>> = axis_and_status
    case b do
      48 -> {q, {:report_calibration, <<a>>, :idle}}
      49 -> {q, {:report_calibration, <<a>>, :home}}
      50 -> {q, {:report_calibration, <<a>>, :end}}
    end
  end

  @spec parse_version(binary) :: {binary, {:report_software_version, binary}}
  defp parse_version(version) do
    [derp | [code]] = String.split(version, " Q")
    {code, {:report_software_version, derp}}
  end

  @doc ~S"""
    Parses R82 codes
    Example:
      iex> Gcode.parse_report_current_position("X34 Y756 Z23")
      {:report_current_position, 34, 756, 23, "0"}
  """
  @lint false
  @spec parse_report_current_position(binary)
  :: {binary, {:report_current_position, binary, binary, binary}}
  def parse_report_current_position(position) when is_bitstring(position),
    do: position |> String.split(" ") |> do_parse_pos

  defp do_parse_pos(["X" <> x, "Y" <> y, "Z" <> z, "Q" <> tag]) do
    {tag, {:report_current_position,
      String.to_integer(x),
      String.to_integer(y),
      String.to_integer(z)}}
  end

  @doc ~S"""
    Parses End Stops. I don't think we actually use these yet.
    Example:
      iex> Gcode.parse_end_stops("XA1 XB1 YA0 YB1 ZA0 ZB1 Q123")
      {:reporting_end_stops, "1", "1", "0", "1", "0", "1", "123"}
  """
  @spec parse_end_stops(binary)
  :: {:reporting_end_stops,
      binary,
      binary,
      binary,
      binary,
      binary,
      binary,
      binary}
  def parse_end_stops(
    <<
      "XA", xa :: size(8), 32,
      "XB", xb :: size(8), 32,
      "YA", ya :: size(8), 32,
      "YB", yb :: size(8), 32,
      "ZA", za :: size(8), 32,
      "ZB", zb :: size(8), 32,
      "Q", tag :: binary
    >>), do: {tag, {:reporting_end_stops,
              xa |> pes,
              xb |> pes,
              ya |> pes,
              yb |> pes,
              za |> pes,
              zb |> pes}}

  @spec pes(48 | 49) :: 0 | 1 # lol
  defp pes(48), do: 0
  defp pes(49), do: 1

  @doc ~S"""
    common function for report_(something)_value from gcode.
    Example:
      iex> Gcode.parse_pvq("P20 V100", :report_parameter_value)
      {:report_parameter_value, "20" ,"100", "0"}

    Example:
      iex> Gcode.parse_pvq("P20 V100 Q12", :report_parameter_value)
      {:report_parameter_value, "20" ,"100", "12"}
  """
  @lint false
  @spec parse_pvq(binary, :report_parameter_value)
  :: {:report_parameter_value, atom, integer, String.t}
  def parse_pvq(params, :report_parameter_value)
  when is_bitstring(params),
    do: params |> String.split(" ") |> do_parse_params

  @lint false
  def parse_pvq(params, human_readable_param_name)
  when is_bitstring(params)
   and is_atom(human_readable_param_name),
   do: params |> String.split(" ") |> do_parse_pvq(human_readable_param_name)

  defp do_parse_pvq([p, v, q], human_readable_param_name) do
    [_, rp] = String.split(p, "P")
    [_, rv] = String.split(v, "V")
    [_, rq] = String.split(q, "Q")
    {rq, {human_readable_param_name,
     String.to_integer(rp),
     String.to_integer(rv)}}
  end

  defp do_parse_params([p, v, q]) do
    [_, rp] = String.split(p, "P")
    [_, rv] = String.split(v, "V")
    [_, rq] = String.split(q, "Q")
    {rq, {:report_parameter_value, parse_param(rp), String.to_integer(rv)}}
  end

  @doc ~S"""
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
  def parse_param("0"), do: :param_version

  def parse_param("11"), do: :movement_timeout_x
  def parse_param("12"), do: :movement_timeout_y
  def parse_param("13"), do: :movement_timeout_z

  def parse_param("21"), do: :movement_invert_endpoints_x
  def parse_param("22"), do: :movement_invert_endpoints_y
  def parse_param("23"), do: :movement_invert_endpoints_z

  def parse_param("25"), do: :movement_enable_endpoints_x
  def parse_param("26"), do: :movement_enable_endpoints_y
  def parse_param("27"), do: :movement_enable_endpoints_z

  def parse_param("31"), do: :movement_invert_motor_x
  def parse_param("32"), do: :movement_invert_motor_y
  def parse_param("33"), do: :movement_invert_motor_z

  def parse_param("36"), do: :movement_secondary_motor_x
  def parse_param("37"), do: :movement_secondary_motor_invert_x

  def parse_param("41"), do: :movement_steps_acc_dec_x
  def parse_param("42"), do: :movement_steps_acc_dec_y
  def parse_param("43"), do: :movement_steps_acc_dec_z

  def parse_param("51"), do: :movement_home_up_x
  def parse_param("52"), do: :movement_home_up_y
  def parse_param("53"), do: :movement_home_up_z

  def parse_param("61"), do: :movement_min_spd_x
  def parse_param("62"), do: :movement_min_spd_y
  def parse_param("63"), do: :movement_min_spd_z

  def parse_param("71"), do: :movement_max_spd_x
  def parse_param("72"), do: :movement_max_spd_y
  def parse_param("73"), do: :movement_max_spd_z

  def parse_param("101"), do: :encoder_enabled_x
  def parse_param("102"), do: :encoder_enabled_y
  def parse_param("103"), do: :encoder_enabled_z

  def parse_param("105"), do: :encoder_type_x
  def parse_param("106"), do: :encoder_type_y
  def parse_param("107"), do: :encoder_type_z

  def parse_param("111"), do: :encoder_missed_steps_max_x
  def parse_param("112"), do: :encoder_missed_steps_max_y
  def parse_param("113"), do: :encoder_missed_steps_max_z

  def parse_param("115"), do: :encoder_scaling_x
  def parse_param("116"), do: :encoder_scaling_y
  def parse_param("117"), do: :encoder_scaling_z

  def parse_param("121"), do: :encoder_missed_steps_decay_x
  def parse_param("122"), do: :encoder_missed_steps_decay_y
  def parse_param("123"), do: :encoder_missed_steps_decay_z

  def parse_param("141"), do: :movement_axis_nr_steps_x
  def parse_param("142"), do: :movement_axis_nr_steps_y
  def parse_param("143"), do: :movement_axis_nr_steps_z

  def parse_param("201"), do: :pin_guard_1_pin_nr
  def parse_param("202"), do: :pin_guard_1_pin_time_out
  def parse_param("203"), do: :pin_guard_1_active_state

  def parse_param("205"), do: :pin_guard_2_pin_nr
  def parse_param("206"), do: :pin_guard_2_pin_time_out
  def parse_param("207"), do: :pin_guard_2_active_state

  def parse_param("211"), do: :pin_guard_3_pin_nr
  def parse_param("212"), do: :pin_guard_3_pin_time_out
  def parse_param("213"), do: :pin_guard_3_active_state

  def parse_param("215"), do: :pin_guard_4_pin_nr
  def parse_param("216"), do: :pin_guard_4_pin_time_out
  def parse_param("217"), do: :pin_guard_4_active_state

  def parse_param("221"), do: :pin_guard_5_pin_nr
  def parse_param("222"), do: :pin_guard_5_time_out
  def parse_param("223"), do: :pin_guard_5_active_state
  @lint false
  def parse_param(param) when is_integer(param), do: parse_param("#{param}")

  @spec parse_param(atom) :: integer | nil
  def parse_param(:param_version), do: 0

  def parse_param(:movement_timeout_x), do: 11
  def parse_param(:movement_timeout_y), do: 12
  def parse_param(:movement_timeout_z), do: 13

  def parse_param(:movement_invert_endpoints_x), do: 21
  def parse_param(:movement_invert_endpoints_y), do: 22
  def parse_param(:movement_invert_endpoints_z), do: 23

  def parse_param(:movement_invert_motor_x), do: 31
  def parse_param(:movement_invert_motor_y), do: 32
  def parse_param(:movement_invert_motor_z), do: 33

  def parse_param(:movement_enable_endpoints_x), do: 25
  def parse_param(:movement_enable_endpoints_y), do: 26
  def parse_param(:movement_enable_endpoints_z), do: 27

  def parse_param(:movement_secondary_motor_x), do: 36
  def parse_param(:movement_secondary_motor_invert_x), do: 37

  def parse_param(:movement_steps_acc_dec_x), do: 41
  def parse_param(:movement_steps_acc_dec_y), do: 42
  def parse_param(:movement_steps_acc_dec_z), do: 43

  def parse_param(:movement_home_up_x), do: 51
  def parse_param(:movement_home_up_y), do: 52
  def parse_param(:movement_home_up_z), do: 53

  def parse_param(:movement_min_spd_x), do: 61
  def parse_param(:movement_min_spd_y), do: 62
  def parse_param(:movement_min_spd_z), do: 63

  def parse_param(:movement_max_spd_x), do: 71
  def parse_param(:movement_max_spd_y), do: 72
  def parse_param(:movement_max_spd_z), do: 73

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

  def parse_param(:movement_axis_nr_steps_x), do: 141
  def parse_param(:movement_axis_nr_steps_y), do: 142
  def parse_param(:movement_axis_nr_steps_z), do: 143

  def parse_param(:pin_guard_1_pin_nr), do: 201
  def parse_param(:pin_guard_1_pin_time_out), do: 202
  def parse_param(:pin_guard_1_active_state), do: 203

  def parse_param(:pin_guard_2_pin_nr), do: 205
  def parse_param(:pin_guard_2_pin_time_out), do: 206
  def parse_param(:pin_guard_2_active_state), do: 207

  def parse_param(:pin_guard_3_pin_nr), do: 211
  def parse_param(:pin_guard_3_pin_time_out), do: 212
  def parse_param(:pin_guard_3_active_state), do: 213

  def parse_param(:pin_guard_4_pin_nr), do: 215
  def parse_param(:pin_guard_4_pin_time_out), do: 216
  def parse_param(:pin_guard_4_active_state), do: 217

  def parse_param(:pin_guard_5_pin_nr), do: 221
  def parse_param(:pin_guard_5_time_out), do: 222
  def parse_param(:pin_guard_5_active_state), do: 223

  def parse_param(param_string) when is_bitstring(param_string),
    do: param_string |> String.to_atom |> parse_param

  # derp.
  if Mix.env == :dev do
    def parse_param(uhh) do
      Logger.error("LOOK AT ME IM IMPORTANT: #{inspect uhh}")
      nil
    end
  else
    def parse_param(_), do: nil
  end
end
