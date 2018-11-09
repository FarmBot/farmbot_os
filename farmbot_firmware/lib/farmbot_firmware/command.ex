defmodule Farmbot.Firmware.Command do
  @moduledoc false
  alias Farmbot.{Firmware, Firmware.GCODE}

  @spec command(GenServer.server(), GCODE.t() | {GCODE.kind(), GCODE.args()}) ::
          :ok | {:error, :invalid_command | :firmware_error | :emergency_lock | Firmware.status()}
  def command(firmware_server \\ Firmware, code)

  def command(firmware_server, {_tag, {_, _}} = code) do
    case GenServer.call(firmware_server, code, :infinity) do
      {:ok, tag} -> wait_for_command_result(tag, code)
      {:error, status} -> {:error, status}
    end
  end

  def command(firmware_server, {_, _} = code) do
    command(firmware_server, {to_string(:rand.uniform(100)), code})
  end

  defp wait_for_command_result(tag, code) do
    receive do
      {^tag, {:report_begin, []}} ->
        wait_for_command_result(tag, code)

      {^tag, {:report_busy, []}} ->
        wait_for_command_result(tag, code)

      {^tag, {:report_success, []}} ->
        :ok

      {^tag, {:report_error, []}} ->
        {:error, :firmware_error}

      {^tag, {:report_invalid, []}} ->
        {:error, :invalid_command}

      {_, {:report_emergency_lock, []}} ->
        {:error, :emergency_lock}

      {_tag, _report} ->
        wait_for_command_result(tag, code)
    end
  end
end
