defmodule Farmbot.Firmware.GCODE.Encoder do
  @moduledoc false

  alias Farmbot.Firmware.{GCODE, Param}

  @doc false
  @spec do_encode(GCODE.kind(), GCODE.args()) :: binary()
  def do_encode(:report_idle, []), do: "R00"
  def do_encode(:report_begin, []), do: "R01"
  def do_encode(:report_success, []), do: "R02"
  def do_encode(:report_error, []), do: "R03"
  def do_encode(:report_busy, []), do: "R04"

  def do_encode(:report_axis_state, xyz), do: "R05 " <> encode_axis_state(xyz)
  def do_encode(:report_calibration_state, xyz), do: "R06 " <> encode_calibration_state(xyz)

  def do_encode(:report_retry, []), do: "R07"
  def do_encode(:report_echo, [echo]), do: "R08 * #{echo} *"
  def do_encode(:report_invalid, []), do: "R09"

  def do_encode(:report_home_complete, [:x]), do: "R11"
  def do_encode(:report_home_complete, [:y]), do: "R12"
  def do_encode(:report_home_complete, [:z]), do: "R13"

  def do_encode(:report_position, [x: _] = arg), do: "R15 " <> encode_floats(arg)
  def do_encode(:report_position, [y: _] = arg), do: "R16 " <> encode_floats(arg)
  def do_encode(:report_position, [z: _] = arg), do: "R16 " <> encode_floats(arg)

  def do_encode(:report_paramaters_complete, []), do: "R20"

  def do_encode(:report_parmater, pv), do: "R21 " <> encode_pv(pv)
  def do_encode(:report_calibration_paramater, pv), do: "R23 " <> encode_pv(pv)
  def do_encode(:report_status_value, pv), do: "R33 " <> encode_ints(pv)
  def do_encode(:report_pin_value, pv), do: "R41 " <> encode_ints(pv)

  def do_encode(:report_axis_timeout, [:x]), do: "R71"
  def do_encode(:report_axis_timeout, [:y]), do: "R72"
  def do_encode(:report_axis_timeout, [:z]), do: "R73"

  def do_encode(:report_end_stops, xxyyzz), do: "R81 " <> encode_end_stops(xxyyzz)
  def do_encode(:report_position, xyzs), do: "R82 " <> encode_floats(xyzs)

  def do_encode(:report_version, [version]), do: "R83 " <> version

  def do_encode(:report_encoders_scaled, xyz), do: "R84 " <> encode_floats(xyz)
  def do_encode(:report_encoders_raw, xyz), do: "R85 " <> encode_floats(xyz)

  def do_encode(:report_emergency_lock, []), do: "R87"
  def do_encode(:report_no_config, []), do: "R88"
  def do_encode(:report_debug_message, [message]), do: "R99 " <> message

  def do_encode(:command_movement, xyzs), do: "G00 " <> encode_floats(xyzs)
  def do_encode(:command_movement_home, []), do: "G38"

  def do_encode(:command_movement_find_home, [:x]), do: "F11"
  def do_encode(:command_movement_find_home, [:y]), do: "F12"
  def do_encode(:command_movement_find_home, [:z]), do: "F13"

  def do_encode(:command_movement_calibrate, [:x]), do: "F14"
  def do_encode(:command_movement_calibrate, [:y]), do: "F15"
  def do_encode(:command_movement_calibrate, [:z]), do: "F16"

  def do_encode(:paramater_read_all, []), do: "F20"
  def do_encode(:paramater_read, [paramater]), do: "F21 #{Param.encode(paramater)}"
  def do_encode(:paramater_write, pv), do: "F22 " <> encode_pv(pv)
  def do_encode(:calibration_paramater_write, pv), do: "F23 " <> encode_pv(pv)
  def do_encode(:status_read, [status_id]), do: "F31 #{status_id}"
  def do_encode(:status_write, pv), do: "F32 " <> encode_ints(pv)
  def do_encode(:pin_write, pv), do: "F41 " <> encode_ints(pv)
  def do_encode(:pin_read, pv), do: "F42 " <> encode_ints(pv)
  def do_encode(:pin_mode_write, pm), do: "F43 " <> encode_ints(pm)
  def do_encode(:servo_write, pv), do: "F61 " <> encode_ints(pv)
  def do_encode(:end_stops_read, []), do: "F81"
  def do_encode(:position_read, []), do: "F82"
  def do_encode(:software_version_read, []), do: "F83"
  def do_encode(:position_write_zero, xyzs), do: "F84" <> encode_ints(xyzs)

  def do_encode(:command_emergency_unlock, _), do: "F09"
  def do_encode(:command_emergency_lock, _), do: "E"

  @spec encode_floats([{Param.t(), float()}]) :: binary()
  defp encode_floats(args) do
    Enum.map(args, fn {param, value} ->
      binary_float = :erlang.float_to_binary(value, decimals: 2)
      String.upcase(to_string(param)) <> binary_float
    end)
    |> Enum.join(" ")
  end

  defp encode_axis_state([{axis, :idle}]),
    do: String.upcase(to_string(axis)) <> "0"

  defp encode_axis_state([{axis, :begin}]),
    do: String.upcase(to_string(axis)) <> "1"

  defp encode_axis_state([{axis, :accelerate}]),
    do: String.upcase(to_string(axis)) <> "2"

  defp encode_axis_state([{axis, :cruise}]),
    do: String.upcase(to_string(axis)) <> "3"

  defp encode_axis_state([{axis, :decelerate}]),
    do: String.upcase(to_string(axis)) <> "4"

  defp encode_axis_state([{axis, :stop}]),
    do: String.upcase(to_string(axis)) <> "5"

  defp encode_axis_state([{axis, :crawl}]),
    do: String.upcase(to_string(axis)) <> "6"

  defp encode_calibration_state([{axis, :idle}]),
    do: String.upcase(to_string(axis)) <> "0"

  defp encode_calibration_state([{axis, :home}]),
    do: String.upcase(to_string(axis)) <> "1"

  defp encode_calibration_state([{axis, :end}]),
    do: String.upcase(to_string(axis)) <> "2"

  defp encode_end_stops(xa: xa, xb: xb, ya: ya, yb: yb, za: za, zb: zb) do
    "XA#{xa} XB#{xb} YA#{ya} YB#{yb} ZA#{za} ZB#{zb}"
  end

  defp encode_pv([{param, value}]) do
    param_id = Param.encode(param)
    binary_float = :erlang.float_to_binary(value, decimals: 2)
    "P#{param_id} V#{binary_float}"
  end

  defp encode_ints(args) do
    Enum.map(args, fn {key, val} ->
      String.upcase(to_string(key)) <> to_string(val)
    end)
    |> Enum.join(" ")
  end
end
