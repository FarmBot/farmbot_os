defmodule Farmbot.Firmware.Gcode.Parser do
  @moduledoc """
  Parses [farmbot-arduino-firmware](https://github.com/farmbot/farmbot-arduino-firmware) G-Codes.
  """

  import Farmbot.Firmware.Gcode.Param

  @spec parse_code(binary) :: {binary, tuple}

  # Status codes.
  @doc "Parse a code to an Elixir consumable message."
  def parse_code("R00 Q" <> tag), do: {tag, :idle}
  def parse_code("R01 Q" <> tag), do: {tag, :received}
  def parse_code("R02 Q" <> tag), do: {tag, :done}
  def parse_code("R03 Q" <> tag), do: {tag, :error}
  def parse_code("R04 Q" <> tag), do: {tag, :busy}

  def parse_code("R05" <> _r), do: {nil, :noop}
  def parse_code("R06 " <> r), do: parse_report_calibration(r)
  def parse_code("R07 " <> _), do: {nil, :noop}
  def parse_code("R08 " <> echo),
    do: {:echo, {:echo, String.replace(echo, "\r", "")}}
  def parse_code("R09 " <> tag),  do: {tag, :invalid_command}

  # Report axis homing.
  def parse_code("R11 " <> tag), do: {tag, :report_axis_home_complete_x}
  def parse_code("R12 " <> tag), do: {tag, :report_axis_home_complete_y}
  def parse_code("R13 " <> tag), do: {tag, :report_axis_home_complete_z}

  # Param report.
  def parse_code("R20 Q" <> tag), do: {tag, :report_params_complete}
  def parse_code("R21 " <> params), do: parse_pvq(params, :report_parameter_value)
  def parse_code("R23 " <> params), do: parse_report_axis_calibration(params)
  def parse_code("R31 " <> params), do: parse_pvq(params, :report_status_value)
  def parse_code("R41 " <> params), do: parse_pvq(params, :report_pin_value)

  # Report Position.
  def parse_code("R81 " <> params), do: parse_end_stops(params)
  def parse_code("R82 " <> p), do: report_xyz(p, :report_current_position)
  def parse_code("R83 " <> v), do: parse_version(v)
  def parse_code("R84 " <> p), do: report_xyz(p, :report_encoder_position_scaled)
  def parse_code("R85 " <> p), do: report_xyz(p, :report_encoder_position_raw)
  def parse_code("R87 Q" <> q), do: {q, :report_emergency_lock}

  def parse_code("R99 " <> message) do
    {nil, {:debug_message, message}}
  end

  # I think this is a bug
  def parse_code("Command" <> _), do: {nil, :noop}

  def parse_code(code) do
    {:unhandled_gcode, code}
  end

  @spec parse_report_calibration(binary)
    :: {binary, {:report_calibration, binary, binary}}
  defp parse_report_calibration(r) do
    [axis_and_status | [q]] = String.split(r, " Q")
    <<a::size(8), b::size(8)>> = axis_and_status

    case <<b>> do
      "0" -> {q, {:report_calibration, <<a>>, :idle}}
      "1" -> {q, {:report_calibration, <<a>>, :home}}
      "2" -> {q, {:report_calibration, <<a>>, :end}}
    end
  end

  defp parse_report_axis_calibration(params) do
    ["P" <> parm, "V" <> val, "Q" <> tag] = String.split(params, " ")

    if parm in ["141", "142", "143"] do
      parm_name  = :report_axis_calibration
      result = parse_param(String.to_integer(parm))
      case Float.parse(val) do
        {float, _} ->
          msg = {parm_name, result, float}
          {tag, msg}
        :error ->
          msg = {parm_name, result, String.to_integer(val)}
          {tag, msg}
      end
    else
      {tag, :noop}
    end
  end

  @spec parse_version(binary) :: {binary, {:report_software_version, binary}}
  defp parse_version(version) do
    [v | [code]] = String.split(version, " Q")
    {code, {:report_software_version, v}}
  end

  @type reporter ::
          :report_current_position
          | :report_encoder_position_scaled
          | :report_encoder_position_raw

  @spec report_xyz(binary, reporter)
    :: {binary, {reporter, binary, binary, binary}}
  defp report_xyz(position, reporter) when is_bitstring(position),
    do: position |> String.split(" ") |> do_parse_pos(reporter)

  @valid_position_reporters [
    :report_current_position,
    :report_encoder_position_scaled
  ]
  defp do_parse_pos(["X" <> x, "Y" <> y, "Z" <> z, "Q" <> tag], reporter)
     when reporter in @valid_position_reporters
   do
     import String, only: [to_float: 1]
     msg = {reporter, to_float(x), to_float(y), to_float(z)}
     {tag, msg}
  end

  defp do_parse_pos(["X" <> x, "Y" <> y, "Z" <> z, "Q" <> tag], reporter) do
    import String, only: [to_integer: 1]
    msg = {reporter, to_integer(x), to_integer(y), to_integer(z)}
    {tag, msg}
  end

  defp do_parse_pos(l, _) do
    {:unhandled_gcode, Enum.join(l, " ")}
  end

  @doc false
  @spec parse_end_stops(binary)
    :: {:report_end_stops,
        binary, binary, binary, binary, binary, binary, binary}
  def parse_end_stops(
    <<"XA", xa::size(8), 32,
      "XB", xb::size(8), 32,
      "YA", ya::size(8), 32,
      "YB", yb::size(8), 32,
      "ZA", za::size(8), 32,
      "ZB", zb::size(8), 32,
      "Q", tag::binary >>)
  do
    r = :report_end_stops
    msg = {r, xa |> pes, xb |> pes, ya |> pes, yb |> pes, za |> pes, zb |> pes}
    {tag, msg}
  end

  # lol
  @spec pes(48 | 49) :: 0 | 1
  defp pes(48), do: 0
  defp pes(49), do: 1

  @doc false
  @spec parse_pvq(binary, :report_parameter_value) ::
          {:report_parameter_value, atom, integer, String.t()}
  def parse_pvq(params, :report_parameter_value)
      when is_bitstring(params),
      do: params |> String.split(" ") |> do_parse_params

  def parse_pvq(params, human_readable_param_name)
      when is_bitstring(params) and is_atom(human_readable_param_name),
      do: params |> String.split(" ") |> do_parse_pvq(human_readable_param_name)

  defp do_parse_pvq([p, v, q], human_readable_param_name) do
    import String, only: [split: 2, to_integer: 1]
    [_, rp] = split(p, "P")
    [_, rv] = split(v, "V")
    [_, rq] = split(q, "Q")
    {rq, {human_readable_param_name, to_integer(rp), to_integer(rv)}}
  end

  defp do_parse_params([p, v, q]) do
    import String, only: [split: 2, to_integer: 1]
    [_, rp] = split(p, "P")
    [_, rv] = split(v, "V")
    [_, rq] = split(q, "Q")
    {rq, {:report_parameter_value, parse_param(to_integer(rp)), to_integer(rv)}}
  end
end
