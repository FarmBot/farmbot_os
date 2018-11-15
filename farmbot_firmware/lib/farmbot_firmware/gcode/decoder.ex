defmodule Farmbot.Firmware.GCODE.Decoder do
  @moduledoc false

  alias Farmbot.Firmware.{GCODE, Param}

  @doc false
  @spec do_decode(binary(), [binary()]) :: {GCODE.kind(), GCODE.args()}
  def do_decode("R00", []), do: {:report_idle, []}
  def do_decode("R01", []), do: {:report_begin, []}
  def do_decode("R02", []), do: {:report_success, []}
  def do_decode("R03", []), do: {:report_error, []}
  def do_decode("R04", []), do: {:report_busy, []}

  def do_decode("R05", xyz), do: {:report_axis_state, decode_axis_state(xyz)}
  def do_decode("R06", xyz), do: {:report_calibration_state, decode_calibration_state(xyz)}

  def do_decode("R07", []), do: {:report_retry, []}
  def do_decode("R08", args), do: {:report_echo, decode_echo(Enum.join(args, " "))}
  def do_decode("R09", []), do: {:report_invalid, []}

  def do_decode("R11", []), do: {:report_home_complete, [:x]}
  def do_decode("R12", []), do: {:report_home_complete, [:y]}
  def do_decode("R13", []), do: {:report_home_complete, [:z]}

  def do_decode("R15", x), do: {:report_position_change, decode_floats(x)}
  def do_decode("R16", y), do: {:report_position_change, decode_floats(y)}
  def do_decode("R17", z), do: {:report_position_change, decode_floats(z)}

  def do_decode("R20", []), do: {:report_paramaters_complete, []}

  def do_decode("R21", pv), do: {:report_paramater_value, decode_pv(pv)}
  def do_decode("R23", pv), do: {:report_calibration_paramater_value, decode_pv(pv)}
  def do_decode("R41", pv), do: {:report_pin_value, decode_ints(pv)}

  def do_decode("R71", []), do: {:report_axis_timeout, [:x]}
  def do_decode("R72", []), do: {:report_axis_timeout, [:y]}
  def do_decode("R73", []), do: {:report_axis_timeout, [:z]}

  def do_decode("R81", xxyyzz), do: {:report_end_stops, decode_end_stops(xxyyzz)}
  def do_decode("R82", xyzs), do: {:report_position, decode_floats(xyzs)}

  def do_decode("R83", [version]), do: {:report_software_version, [version]}

  def do_decode("R84", xyz), do: {:report_encoders_scaled, decode_floats(xyz)}
  def do_decode("R85", xyz), do: {:report_encoders_raw, decode_floats(xyz)}

  def do_decode("R87", []), do: {:report_emergency_lock, []}
  def do_decode("R88", []), do: {:report_no_config, []}
  def do_decode("R99", debug), do: {:report_debug_message, [Enum.join(debug, " ")]}

  def do_decode("G00", xyzs), do: {:command_movement, decode_floats(xyzs)}
  def do_decode("G28", []), do: {:comand_movement_home, [:x, :y, :z]}

  def do_decode("F11", []), do: {:command_movement_find_home, [:x]}
  def do_decode("F12", []), do: {:command_movement_find_home, [:y]}
  def do_decode("F13", []), do: {:command_movement_find_home, [:z]}

  def do_decode("F14", []), do: {:command_movement_calibrate, [:x]}
  def do_decode("F15", []), do: {:command_movement_calibrate, [:y]}
  def do_decode("F16", []), do: {:command_movement_calibrate, [:z]}

  def do_decode("F20", []), do: {:paramater_read_all, []}
  def do_decode("F21", [param_id]), do: {:paramater_read, [Param.decode(param_id)]}
  def do_decode("F22", pv), do: {:paramater_write, decode_pv(pv)}
  def do_decode("F23", pv), do: {:calibration_paramater_write, decode_pv(pv)}

  def do_decode("F41", pvm), do: {:pin_write, decode_ints(pvm)}
  def do_decode("F42", pv), do: {:pin_read, decode_ints(pv)}
  def do_decode("F43", pm), do: {:pin_mode_write, decode_ints(pm)}

  def do_decode("F61", pv), do: {:servo_write, decode_ints(pv)}

  def do_decode("F81", []), do: {:end_stops_read, []}
  def do_decode("F82", []), do: {:position_read, []}
  def do_decode("F83", []), do: {:software_version_read, []}
  def do_decode("F84", xyzs), do: {:position_write_zero, decode_ints(xyzs)}

  def do_decode("F09", _), do: {:command_emergency_unlock, []}
  def do_decode("E", _), do: {:command_emergency_lock, []}

  def do_decode(kind, args) do
    {:unknown, [kind | args]}
  end

  defp decode_floats(list, acc \\ [])

  defp decode_floats([<<arg::binary-1, val::binary>> | rest], acc) do
    arg =
      arg
      |> String.downcase()
      |> String.to_existing_atom()

    case Float.parse(val) do
      {num, ""} ->
        decode_floats(rest, Keyword.put(acc, arg, num))

      _ ->
        case Integer.parse(val) do
          {num, ""} -> decode_floats(rest, Keyword.put(acc, arg, num / 1))
          _ -> decode_floats(rest, acc)
        end
    end
  end

  # This is sort of order dependent and not exactly correct.
  # It should ensure the order is [x: _, y: _, z: _]
  defp decode_floats([], acc), do: Enum.reverse(acc)

  defp decode_axis_state(list) do
    args = decode_floats(list)

    Enum.map(args, fn {axis, value} ->
      case value do
        0.0 -> {axis, :idle}
        1.0 -> {axis, :begin}
        2.0 -> {axis, :accelerate}
        3.0 -> {axis, :cruise}
        4.0 -> {axis, :decelerate}
        5.0 -> {axis, :stop}
        6.0 -> {axis, :crawl}
      end
    end)
  end

  defp decode_calibration_state(list) do
    args = decode_floats(list)

    Enum.map(args, fn {axis, value} ->
      case value do
        0.0 -> {axis, :idle}
        1.0 -> {axis, :home}
        2.0 -> {axis, :end}
      end
    end)
  end

  @spec decode_end_stops([binary()], Keyword.t()) :: Keyword.t()
  defp decode_end_stops(list, acc \\ [])

  defp decode_end_stops(
         [<<arg::binary-1, "A", val0::binary>>, <<arg::binary-1, "B", val1::binary>> | rest],
         acc
       ) do
    dc = String.downcase(arg)

    acc =
      acc ++
        [
          {:"#{dc}a", String.to_integer(val0)},
          {:"#{dc}b", String.to_integer(val1)}
        ]

    decode_end_stops(rest, acc)
  end

  defp decode_end_stops([], acc), do: acc

  defp decode_pv(["P" <> param_id, "V" <> value]) do
    param = Param.decode(String.to_integer(param_id))
    {value, ""} = Float.parse(value)
    [{param, value}]
  end

  defp decode_ints(pvm, acc \\ [])

  defp decode_ints([<<arg::binary-1, val::binary>> | rest], acc) do
    arg =
      arg
      |> String.downcase()
      |> String.to_existing_atom()

    case Integer.parse(val) do
      {num, ""} -> decode_ints(rest, Keyword.put(acc, arg, num))
      _ -> decode_ints(rest, acc)
    end
  end

  defp decode_ints([], acc), do: Enum.reverse(acc)

  @spec decode_echo(binary()) :: [binary()]
  defp decode_echo(str) when is_binary(str) do
    [_, echo | _] = String.split(str, "*", parts: 3)
    [String.trim(echo)]
  end
end
