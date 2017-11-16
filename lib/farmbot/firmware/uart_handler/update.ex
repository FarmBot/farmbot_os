defmodule Farmbot.Firmware.UartHandler.Update do
  @moduledoc false
  use Farmbot.Logger
  def maybe_update_firmware(hardware \\ nil) do
    tty = Application.get_all_env(:farmbot)[:uart_handler][:tty]
    hardware = case hardware do
      "farmduino" -> "F"
      "arduino" -> "R"
      nil -> "R"
    end
    if tty do
      do_connect_and_maybe_update(tty, hardware)
    end
  end

  defp do_connect_and_maybe_update(tty, hardware) do
    case Nerves.UART.start_link() do
      {:ok, uart} ->
        opts = [
          active: true,
          framing: {Nerves.UART.Framing.Line, separator: "\r\n"},
          speed: 115200
        ]
        :ok = Nerves.UART.open(uart, tty, [speed: 115200])
        :ok = Nerves.UART.configure(uart, opts)
        Logger.busy 3, "Waiting for firmware idle report."
        do_fw_loop(uart, tty, :idle, hardware)
      {:error, reason} ->
        Logger.error 1, "Failed to connect to firmware for update: #{inspect reason}"
    end
  end

  defp do_fw_loop(uart, tty, flag, hardware) do
    receive do
      {:nerves_uart, _, {:error, reason}} ->
        Logger.error 1, "Failed to connect to firmware for update during idle step: #{inspect reason}"
        close(uart, tty)
      {:nerves_uart, _, data} ->
        if String.contains?(data, "R00") do
          case flag do
            :idle ->
              Logger.busy 3, "Waiting for next idle."
              do_fw_loop(uart, tty, :version, hardware)
            :version ->
              Process.sleep(500)
              # tell the FW to report its version.
              Nerves.UART.write(uart, "F83")
              Logger.busy 3, "Waiting for firmware version report."
              do_wait_version(uart, tty, hardware)
          end
        else
          do_fw_loop(uart, tty, flag, hardware)
        end
    after
      15_000 ->
        Logger.warn 1, "timeout waiting for firmware idle. Forcing flash."
        do_flash(hardware, uart, tty)
    end
  end

  defp do_wait_version(uart, tty, hardware) do
    receive do
      {:nerves_uart, _, {:error, reason}} ->
        Logger.error 1, "Failed to connect to firmware for update: #{inspect reason}"
        close(uart, tty)
      {:nerves_uart, _, data} ->
        case String.split(data, "R83 ") do
          [_] ->
            # IO.puts "got data: #{data}"
            do_wait_version(uart, tty, hardware)
          ["", ver_with_q] -> do_maybe_flash(ver_with_q, uart, tty, hardware)
        end
    after
      15_000 ->
        Logger.warn 1, "timeout waiting for firmware version. Forcing flash."
        do_flash(hardware, uart, tty)
    end
  end

  defp do_maybe_flash(ver_with_q, uart, tty, hardware) do
    current_version = case String.split(ver_with_q, " Q") do
      [ver] -> ver
      [ver, _] -> ver
    end
    expected = Application.get_env(:farmbot, :expected_fw_versions)
    fw_hw = String.last(current_version)
    cond do
      fw_hw != hardware ->
        Logger.warn 3, "Switching firmware hardware."
        do_flash(hardware, uart, tty)
      current_version in expected ->
        Logger.success 1, "Firmware is already correct version."
      true ->
        Logger.busy 1, "#{current_version} != #{inspect expected}"
        do_flash(fw_hw, uart, tty)
    end
  end

  # Farmduino
  defp do_flash("F", uart, tty) do
    avrdude("#{:code.priv_dir(:farmbot)}/farmduino-firmware.hex", uart, tty)
  end

  # Anything else. (should always be "R")
  defp do_flash(_, uart, tty) do
    avrdude("#{:code.priv_dir(:farmbot)}/arduino-firmware.hex", uart, tty)
  end

  defp close(uart, _tty) do
    if Process.alive?(uart) do
      Nerves.UART.close(uart)
      Nerves.UART.stop(uart)
      Process.sleep(500) # to allow the FD to be closed.
    end
  end

  def avrdude(fw_file, uart, tty) do
    close(uart, tty)
    case System.cmd("avrdude", ~w"-q -q -patmega2560 -cwiring -P#{tty} -b115200 -D -V -Uflash:w:#{fw_file}:i", [stderr_to_stdout: true, into: IO.stream(:stdio, :line)]) do
      {_, 0} -> Logger.success 1, "Firmware flashed!"
      {_, err_code} -> Logger.error 1, "Failed to flash Firmware! #{err_code}"
    end
  end
end
