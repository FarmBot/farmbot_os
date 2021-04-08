defmodule FarmbotCore.Firmware.InboundUART do
  @moduledoc """
  """
  alias FarmbotCore.{BotState, FirmwareEstopTimer}
  require Logger
  require FarmbotCore.Logger

  def process({line_buffer, data}) do
    Enum.map(data, &do_process/1)
    line_buffer
  end

  defp do_process({:debug_message, string}) do
    Logger.debug("Firmware Message: #{inspect(string)}")
  end

  defp do_process({:idle, _}) do
    _ = FirmwareEstopTimer.cancel_timer()
    :ok = BotState.set_firmware_unlocked()
    :ok = BotState.set_firmware_idle(true)
  end

  defp do_process({:current_position, %{x: x, y: y, z: z}}) do
    :ok = BotState.set_position(x, y, z)
  end

  defp do_process({:encoder_position_raw, %{x: x, y: y, z: z}}) do
    :ok = BotState.set_encoders_raw(x, y, z)
  end

  defp do_process({:encoder_position_scaled, %{x: x, y: y, z: z}}) do
    :ok = BotState.set_encoders_scaled(x, y, z)
  end

  defp do_process({:end_stops_report, %{z_endstop_a: za, z_endstop_b: za}}) do
    :noop
  end

  defp do_process({:not_configured, _}) do
    IO.puts("TODO: Handle firmware boot time configuration")
  end

  defp do_process(unknown) do
    error = inspect(unknown)
    msg = "Malformed firmware message: #{error}"
    FarmbotCore.Logger.error(3, msg)
    raise msg
  end
end
