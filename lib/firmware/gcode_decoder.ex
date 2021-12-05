defmodule FarmbotOS.Firmware.GCodeDecoder do
  @moduledoc """
  """

  require Logger

  @response_codes %{
    "00" => :idle,
    "01" => :start,
    "02" => :ok,
    "03" => :error,
    "04" => :running,
    "05" => :axis_state_report,
    "06" => :calibration_state_report,
    "07" => :movement_retry,
    "08" => :echo,
    "09" => :invalidation,
    "11" => :complete_homing_x,
    "12" => :complete_homing_y,
    "13" => :complete_homing_z,
    "15" => :different_x_coordinate_than_given,
    "16" => :different_y_coordinate_than_given,
    "17" => :different_z_coordinate_than_given,
    "20" => :param_completion,
    "21" => :param_value_report,
    "23" => :report_updated_param_during_calibration,
    "41" => :pin_value_report,
    "61" => :report_pin_monitor_analog_value,
    "71" => :x_axis_timeout,
    "72" => :y_axis_timeout,
    "73" => :z_axis_timeout,
    "81" => :end_stops_report,
    "82" => :current_position,
    "83" => :software_version,
    "84" => :encoder_position_scaled,
    "85" => :encoder_position_raw,
    "86" => :abort,
    "87" => :emergency_lock,
    "88" => :not_configured,
    "89" => :motor_load_report,
    "99" => :debug_message
  }

  @params %{
    "A" => :x_speed,
    "B" => :y_speed,
    "C" => :z_speed,
    "E" => :element,
    "M" => :mode,
    "N" => :number,
    "P" => :pin_or_param,
    "Q" => :queue,
    "T" => :seconds,
    "U" => :value0,
    "V" => :value1,
    "W" => :value2,
    "X" => :x,
    "XA" => :z_endstop_a,
    "XB" => :z_endstop_b,
    "Y" => :y,
    "YA" => :z_endstop_a,
    "YB" => :z_endstop_b,
    "Z" => :z,
    "ZA" => :z_endstop_a,
    "ZB" => :z_endstop_b
  }

  def run(messages) do
    messages
    |> Enum.map(&validate_message/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&process/1)
  end

  defp validate_message("R99" <> _ = m), do: m
  defp validate_message("R" <> _ = m), do: m

  defp validate_message(message) do
    log = "Dropping malformed message: #{inspect(message)}"
    Logger.debug(log)
    nil
  end

  defp process("R83" <> rest) do
    version = rest |> String.trim() |> String.split(" ") |> Enum.at(0)
    {response_code("83"), version}
  end

  # Firmware log
  defp process("R99" <> rest) do
    {response_code("99"), String.trim(rest)}
  end

  # Command echo
  defp process("R08" <> rest) do
    {response_code("08"), String.trim(rest)}
  end

  defp process("R" <> <<code::binary-size(2)>> <> rest) do
    {response_code(code), parameterize(rest)}
  end

  defp response_code(code) do
    map_get(@response_codes, code, "firmware response code")
  end

  defp fetch_param!(code, original_string) do
    value = Map.get(@params, code)

    if value do
      value
    else
      msg1 = "(1/2) Parameter decode error: #{inspect(code)}"
      msg2 = "(2/2) Parameter decode error: #{inspect(original_string)}"
      Logger.debug(msg1)
      Logger.debug(msg2)
      raise "BAD PARAMETER: #{inspect(code)} / #{inspect(original_string)}"
    end
  end

  defp parameterize(string) do
    string
    |> String.trim()
    |> String.split(" ")
    |> Enum.filter(fn
      "" -> false
      _ -> true
    end)
    |> Enum.map(fn pair ->
      [number] = Regex.run(~r/-?\d+\.?\d?+/, pair)
      [code] = Regex.run(~r/[A-Z]{1,2}/, pair)
      {float, _} = Float.parse(number)
      {fetch_param!(code, string), float}
    end)
    |> Enum.reduce(%{}, fn {key, val}, acc -> Map.put(acc, key, val) end)
  end

  def map_get(map, value, what) do
    value = Map.get(map, value)

    if value do
      value
    else
      msg = "Failed to look up unexpected #{what}: #{inspect(value)}"
      Logger.debug(msg)
      raise msg
    end
  end
end
