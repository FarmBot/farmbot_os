defmodule FarmbotFirmware.Request do
  @moduledoc false
  alias Farmbot.{Firmware, Firmware.GCODE}

  @spec request(GenServer.server(), GCODE.t()) ::
          {:ok, GCODE.t()} | {:error, :invalid_command | :firmware_error | Firmware.status()}
  def request(firmware_server \\ Firmware, code)

  def request(firmware_server, {_tag, {kind, _}} = code) do
    if kind not in [
         :parameter_read,
         :status_read,
         :pin_read,
         :end_stops_read,
         :position_read,
         :software_version_read
       ] do
      raise ArgumentError, "#{kind} is not a valid request."
    end

    case GenServer.call(firmware_server, code, :infinity) do
      {:ok, tag} -> wait_for_request_result(tag, code)
      {:error, status} -> {:error, status}
    end
  end

  def request(firmware_server, {_, _} = code) do
    request(firmware_server, {to_string(:rand.uniform(100)), code})
  end

  # This is a bit weird but let me explain:
  # if this function `receive`s
  #   * report_error
  #   * report_invalid
  #   * report_emergency_lock
  # it needs to return an error.
  # If this function `receive`s
  #   * report_success
  # when no valid data has been collected from `wait_for_request_result_process`
  # it needs to return an error.
  # If this function `receive`s
  #   * report_success
  # when valid data has been collected from `wait_for_request_result_process`
  # it will return that data.
  # If this function returns no data for 5 seconds, it needs to error.
  defp wait_for_request_result(tag, code, result \\ nil) do
    receive do
      {tag, {:report_begin, []}} ->
        wait_for_request_result(tag, code, result)

      {tag, {:report_busy, []}} ->
        wait_for_request_result(tag, code, result)

      {tag, {:report_success, []}} ->
        if result,
          do: {:ok, {tag, result}},
          else: wait_for_request_result(tag, code, result)

      {_, {:report_error, []}} ->
        {:error, :firmware_error}

      {_, {:report_invalid, []}} ->
        {:error, :invalid_command}

      {_, {:report_emergency_lock, []}} ->
        {:error, :emergency_lock}

      {:error, reason} ->
        {:error, reason}

      {tag, report} ->
        wait_for_request_result_process(report, tag, code, result)
    after
      5_000 ->
        if result, do: {:ok, {tag, result}}, else: {:error, {:timeout, result}}
    end
  end

  # {:parameter_read, [param]} => {:report_parameter_value, [{param, val}]}
  defp wait_for_request_result_process(
         {:report_parameter_value, _} = report,
         tag,
         {_, {:parameter_read, _}} = code,
         _
       ) do
    wait_for_request_result(tag, code, report)
  end

  # {:status_read, [status]} => {:report_status_value, [{status, value}]}
  defp wait_for_request_result_process(
         {:report_status_value, _} = report,
         tag,
         {_, {:status_read, _}} = code,
         _
       ) do
    wait_for_request_result(tag, code, report)
  end

  # {:pin_read, [pin]} => {:report_pin_value, [{pin, value}]}
  defp wait_for_request_result_process(
         {:report_pin_value, _} = report,
         tag,
         {_, {:pin_read, _}} = code,
         _
       ) do
    wait_for_request_result(tag, code, report)
  end

  # {:end_stops_read, []} => {:position_end_stops, end_stops}
  defp wait_for_request_result_process(
         {:report_end_stops, _} = report,
         tag,
         {_, {:end_stops_read, []}} = code,
         _
       ) do
    wait_for_request_result(tag, code, report)
  end

  # {:position_read, []} => {:position_report, [x: x, y: y, z: z]}
  defp wait_for_request_result_process(
         {:report_position, _} = report,
         tag,
         {_, {:position_read, []}} = code,
         _
       ) do
    wait_for_request_result(tag, code, report)
  end

  # {:software_version_read, []} => {:report_software_version, [version]}
  defp wait_for_request_result_process(
         {:report_software_version, _} = report,
         tag,
         {_, {:software_version_read, _}} = code,
         _
       ) do
    wait_for_request_result(tag, code, report)
  end

  defp wait_for_request_result_process(_report, tag, code, result) do
    wait_for_request_result(tag, code, result)
  end
end
