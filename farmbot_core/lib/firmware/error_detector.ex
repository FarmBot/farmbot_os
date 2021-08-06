defmodule FarmbotCore.Firmware.ErrorDetector do
  require Logger
  require FarmbotCore.Logger

  alias FarmbotCore.Firmware.GCode
  # @no_error 0
  # @emergency_stop 1
  @timeout 2
  # @stall_detected 3
  # @calibration_error 4
  # @invalid_command 14
  # @no_config 15

  def detect(@timeout, %GCode{}) do
    FarmbotCore.Logger.error(1, "Movement timeout detected")
  end

  def detect(error_code, gcode_struct) do
    Logger.info("Unhandled GCode error #{error_code}")
    Logger.info("==== gcode_struct: #{inspect(gcode_struct)}")
  end

  # defp get_bad_axis(params) do
  #   {axis, _value} =
  #     params
  #     |> Enum.filter(&is_axis?/1)
  #     |> Enum.max_by(fn {_k, v} -> v end)

  #   axis
  # end

  # defp is_axis?({axis, _value}) when axis in [:X, :Y, :Z], do: true
  # defp is_axis?(_), do: false
end
