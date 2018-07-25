defmodule Farmbot.Firmware.UartHandler.Update do
  @moduledoc false

  require Farmbot.Logger

  @uart_speed 115_200

  def maybe_update_firmware(hardware \\ nil) do
    tty = Application.get_all_env(:farmbot_core)[:uart_handler][:tty]
    hardware = case hardware do
      "farmduino" -> "F"
      "arduino" -> "R"
      "farmduino_k14" -> "G"
      nil -> "R"
    end
    if tty do
      do_connect_and_maybe_update(tty, hardware)
    end
  end

  def force_update_firmware(hardware \\ nil) do
    tty = Application.get_all_env(:farmbot_core)[:uart_handler][:tty]
    hardware = case hardware do
      "farmduino" -> "F"
      "arduino" -> "R"
      "farmduino_k14" -> "G"
      nil -> "R"
    end
    do_flash(hardware, nil, tty)
  end

  defp do_connect_and_maybe_update(tty, hardware) do
    case Nerves.UART.start_link() do
      {:ok, uart} ->
        opts = [
          active: true,
          framing: {Nerves.UART.Framing.Line, separator: "\r\n"},
          speed: @uart_speed
        ]
        :ok = Nerves.UART.open(uart, tty, [speed: @uart_speed])
        :ok = Nerves.UART.configure(uart, opts)
        Farmbot.Logger.busy 3, "Waiting for firmware idle report."
        do_fw_loop(uart, tty, :idle, hardware)
        close(uart)
      {:error, reason} ->
        Farmbot.Logger.error 1, "Failed to connect to firmware for update: #{inspect reason}"
    end
  end

  defp do_fw_loop(uart, tty, flag, hardware) do
    receive do
      {:nerves_uart, _, {:error, reason}} ->
        Farmbot.Logger.error 1, "Failed to connect to firmware for update during idle step: #{inspect reason}"
      {:nerves_uart, _, data} ->
        if String.contains?(data, "R00") do
          case flag do
            :idle ->
              Farmbot.Logger.busy 3, "Waiting for next idle."
              do_fw_loop(uart, tty, :version, hardware)
            :version ->
              Process.sleep(500)
              # tell the FW to report its version.
              Nerves.UART.write(uart, "F83")
              Farmbot.Logger.busy 3, "Waiting for firmware version report."
              do_wait_version(uart, tty, hardware)
          end
        else
          do_fw_loop(uart, tty, flag, hardware)
        end
    after
      15_000 ->
        Farmbot.Logger.warn 1, "timeout waiting for firmware idle. Forcing flash."
        do_flash(hardware, uart, tty)
    end
  end

  defp do_wait_version(uart, tty, hardware) do
    receive do
      {:nerves_uart, _, {:error, reason}} ->
        Farmbot.Logger.error 1, "Failed to connect to firmware for update: #{inspect reason}"
      {:nerves_uart, _, data} ->
        case String.split(data, "R83 ") do
          [_] ->
            # IO.puts "got data: #{data}"
            do_wait_version(uart, tty, hardware)
          ["", ver_with_q] -> do_maybe_flash(ver_with_q, uart, tty, hardware)
        end
    after
      15_000 ->
        Farmbot.Logger.warn 1, "timeout waiting for firmware version. Forcing flash."
        do_flash(hardware, uart, tty)
    end
  end

  defp do_maybe_flash(ver_with_q, uart, tty, hardware) do
    current_version = case String.split(ver_with_q, " Q") do
      [ver] -> ver
      [ver, _] -> ver
    end
    expected = Application.get_env(:farmbot_core, :expected_fw_versions)
    fw_hw = String.last(current_version)
    cond do
      fw_hw != hardware ->
        Farmbot.Logger.warn 3, "Switching firmware hardware."
        do_flash(hardware, uart, tty)
      current_version in expected ->
        Farmbot.Logger.success 1, "Firmware is already correct version."
      true ->
        Farmbot.Logger.busy 1, "#{current_version} != #{inspect expected}"
        do_flash(fw_hw, uart, tty)
    end
  end

  # Farmduino
  defp do_flash("F", uart, tty) do
    avrdude("#{:code.priv_dir(:farmbot_core)}/eeprom_clear.ino.hex", uart, tty)
    Process.sleep(1000)
    avrdude("#{:code.priv_dir(:farmbot_core)}/farmduino.hex", uart, tty)
  end

  defp do_flash("G", uart, tty) do
    avrdude("#{:code.priv_dir(:farmbot_core)}/eeprom_clear.ino.hex", uart, tty)
    Process.sleep(1000)
    avrdude("#{:code.priv_dir(:farmbot_core)}/farmduino_k14.hex", uart, tty)
  end

  # Anything else. (should always be "R")
  defp do_flash(_, uart, tty) do
    avrdude("#{:code.priv_dir(:farmbot_core)}/eeprom_clear.ino.hex", uart, tty)
    Process.sleep(1000)
    avrdude("#{:code.priv_dir(:farmbot_core)}/arduino_firmware.hex", uart, tty)
  end

  defp close(nil) do
    Farmbot.Logger.info 3, "No uart process."
    :ok
  end

  defp close(uart) do
    if Process.alive?(uart) do
      close = Nerves.UART.close(uart)
      stop = Nerves.UART.stop(uart)
      Farmbot.Logger.info 3, "CLOSE: #{inspect close} STOP: #{stop}"
      Process.sleep(2000) # to allow the FD to be closed.
    end
  end

  def avrdude(fw_file, uart, tty) do
    close(uart)
    args = ~w"-patmega2560 -cwiring -P#{tty} -b#{@uart_speed} -D -V -Uflash:w:#{fw_file}:i"
    Farmbot.Logger.busy 3, "Starting avrdude: #{inspect(args)}"
    reset = reset_init()
    opts = [stderr_to_stdout: true, into: IO.stream(:stdio, :line)]
    do_reset(reset)
    res = System.cmd("avrdude", args, opts)
    reset_close(reset)
    Process.sleep(1500) # wait to allow file descriptors to be closed.
    case res do
      {_, 0} ->
        Farmbot.Logger.success 1, "Firmware flashed! #{fw_file}"
        :ok
      {_, err_code} ->
        Farmbot.Logger.error 1, "Failed to flash Firmware! #{fw_file} #{err_code}"
        Farmbot.Firmware.Utils.replace_firmware_handler(Farmbot.Firmware.StubHandler)
        :error
    end
  end

  if Farmbot.Project.target() in ["rpi0", "rpi"] do
    @reset_pin 19
    defp reset_init do
      {:ok, pid} = ElixirALE.GPIO.start_link(@reset_pin, :output)
      pid
    end
    defp do_reset(pid) do
      ElixirALE.GPIO.write(pid, 1)
      ElixirALE.GPIO.write(pid, 0)
    end
    defp reset_close(pid), do: ElixirALE.GPIO.release(pid)
  else
    defp reset_init(), do: nil
    defp do_reset(nil), do: :ok
    defp reset_close(nil), do: :ok
  end
end
