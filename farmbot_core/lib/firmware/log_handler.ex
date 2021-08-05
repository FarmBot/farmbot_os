defmodule FarmbotCore.Firmware.LogHandler do
  require Logger
  require FarmbotCore.Logger

  def handle("DEACTIVATE MOTOR X DUE TO MISSED STEPS"), do: stall(:X)
  def handle("DEACTIVATE MOTOR Y DUE TO MISSED STEPS"), do: stall(:Y)
  def handle("DEACTIVATE MOTOR Z DUE TO MISSED STEPS"), do: stall(:Z)
  def handle("TIMEOUT X" <> _), do: timeout(:X)
  def handle("TIMEOUT Y" <> _), do: timeout(:Y)
  def handle("TIMEOUT Z" <> _), do: timeout(:Z)
  def handle(msg), do: Logger.debug("Firmware Message: #{inspect(msg)}")

  defp stall(axis), do: problem("Stall", axis)
  defp timeout(axis), do: problem("Timeout", axis)

  defp problem(kind, axis) do
    FarmbotCore.Logger.error(1, "#{kind} detected on #{axis} axis")
  end
end
