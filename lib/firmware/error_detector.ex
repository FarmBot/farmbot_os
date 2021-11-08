defmodule FarmbotOS.Firmware.ErrorDetector do
  require Logger
  require FarmbotOS.Logger

  # See `ErrorListEnum` in Farmbot Arduino firmware for
  # complete list of error codes.
  def detect(2), do: log("Movement timed out")
  def detect(31), do: log_stall("X")
  def detect(32), do: log_stall("Y")
  def detect(33), do: log_stall("Z")
  def detect(_), do: nil

  # TODO: We could mark the map with stall points in the
  #       function below.
  defp log_stall(n), do: log("Stall detected on #{n} axis")
  defp log(msg), do: msg
end
