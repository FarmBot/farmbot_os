defmodule FarmbotFirmware.Command do
  @moduledoc false
  # sister module to FarmbotFirmware.Request
  # see docs for FarmbotFirmware.command/1

  alias FarmbotFirmware
  alias FarmbotFirmware.GCODE
  require Logger

  @spec command(GenServer.server(), GCODE.t() | {GCODE.kind(), GCODE.args()}) ::
          :ok
          | {:error,
             :invalid_command | :firmware_error | :emergency_lock | FarmbotFirmware.status()}
  def command(firmware_server \\ FarmbotFirmware, code)

  def command(firmware_server, {_tag, {_, _}} = code) do
    case GenServer.call(firmware_server, code, :infinity) do
      {:ok, tag} -> wait_for_command_result(tag, code)
      {:error, status} -> {:error, status}
    end
  end

  def command(firmware_server, {_, _} = code) do
    command(firmware_server, {to_string(:rand.uniform(100)), code})
  end

  defp wait_for_command_result(_tag, code, retries \\ 0, err \\ nil) do
    receive do
      {tag, {:report_begin, []}} ->
        debug_log("#{GCODE.encode(code)} begin")
        wait_for_command_result(tag, code, retries, err)

      {tag, {:report_busy, []}} ->
        debug_log("#{GCODE.encode(code)} busy")
        wait_for_command_result(tag, code, retries, err)

      {_, {:report_success, []}} ->
        debug_log("#{GCODE.encode(code)} success")
        :ok

      {tag, {:report_retry, []}} ->
        debug_log("#{GCODE.encode(code)} retry")
        wait_for_command_result(tag, code, retries + 1, err)

      {tag, {:report_position_change, _} = error} ->
        debug_log("#{GCODE.encode(code)} position change")
        wait_for_command_result(tag, code, retries, error)

      {_, {:report_error, _}} ->
        debug_log("#{GCODE.encode(code)} firmware error")
        if err, do: {:error, err}, else: {:error, :firmware_error}

      {_, {:report_invalid, []}} ->
        debug_log("#{GCODE.encode(code)} invalid command")
        {:error, :invalid_command}

      {_, {:report_emergency_lock, []}} ->
        debug_log("#{GCODE.encode(code)} e stop")
        {:error, :emergency_lock}

      {_, {:report_axis_timeout, [axis]}} ->
        {:error, "axis timeout: #{axis}"}

      {:error, reason} ->
        debug_log("#{GCODE.encode(code)} unknown error")
        {:error, reason}

      {tag, report} ->
        debug_log("#{GCODE.encode(code)} ignored report: #{inspect(report)}")
        wait_for_command_result(tag, code, retries, err)
    after
      30_000 ->
        raise("Firmware command: #{GCODE.encode(code)} failed to respond within 30 seconds")
    end
  end

  @doc "Enable debug logs"
  def enable_debug_logs() do
    old = Application.get_env(:farmbot_firmware, __MODULE__) || []
    new = Keyword.put(old, :debug_log, true)
    Application.put_env(:farmbot_firmware, __MODULE__, new)
  end

  @doc "Disable debug logs"
  def disable_debug_logs() do
    old = Application.get_env(:farmbot_firmware, __MODULE__) || []
    new = Keyword.put(old, :debug_log, false)
    Application.put_env(:farmbot_firmware, __MODULE__, new)
  end

  defp debug?() do
    Application.get_env(:farmbot_firmware, __MODULE__)[:debug_log] || false
  end

  defp debug_log(msg), do: if(debug?(), do: Logger.debug(msg), else: :ok)
end
