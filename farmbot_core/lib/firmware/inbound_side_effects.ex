defmodule FarmbotCore.Firmware.InboundSideEffects do
  @moduledoc """
  """
  alias FarmbotCore.{BotState, FirmwareEstopTimer}
  alias FarmbotCore.Firmware.TxBuffer

  require Logger
  require FarmbotCore.Logger

  def process(state, gcode) do
    Enum.map(gcode, fn {name, params} ->
      IO.inspect(params, label: "==> #{name}")
    end)

    Enum.reduce(gcode, state, &reduce/2)
  end

  defp reduce({:debug_message, string}, state) do
    Logger.debug("Firmware Message: #{inspect(string)}")
    state
  end

  defp reduce({:idle, _}, state) do
    _ = FirmwareEstopTimer.cancel_timer()
    :ok = BotState.set_firmware_unlocked()
    :ok = BotState.set_firmware_idle(true)
    TxBuffer.process_next_message(state)
    state
  end

  defp reduce({:current_position, %{x: x, y: y, z: z}}, state) do
    :ok = BotState.set_position(x, y, z)
    state
  end

  defp reduce({:encoder_position_raw, %{x: x, y: y, z: z}}, state) do
    :ok = BotState.set_encoders_raw(x, y, z)
    state
  end

  defp reduce({:encoder_position_scaled, %{x: x, y: y, z: z}}, state) do
    :ok = BotState.set_encoders_scaled(x, y, z)
    state
  end

  defp reduce({:end_stops_report, %{z_endstop_a: za, z_endstop_b: za}}, s) do
    :noop
    s
  end

  defp reduce({:not_configured, _}, state) do
    next_state = FarmbotCore.Firmware.ConfigUploader.upload(state)
    next_state
  end

  defp reduce({:emergency_lock, _}, state) do
    IO.puts("Emergency locked...")
    state
  end

  defp reduce(unknown, state) do
    IO.inspect(unknown, label: "=== Unhandled inbound side effects")
    state
  end
end
