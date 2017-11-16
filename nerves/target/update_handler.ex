defmodule Farmbot.Target.UpdateHandler do
  @moduledoc "Handles prep and post OTA update."

  @behaviour Farmbot.System.UpdateHandler
  use Farmbot.Logger

  # Update Handler callbacks

  def apply_firmware(file_path) do
    Nerves.Firmware.upgrade_and_finalize(file_path)
  end

  def before_update do
    :ok
  end

  def post_update do
    maybe_update_firmware()
    :ok
  end

  defp maybe_update_firmware do
    tty = Application.get_all_env(:farmbot)[:uart_handler][:tty]
    if tty do
      do_connect_and_maybe_update(tty)
    end
  end

  defp do_connect_and_maybe_update(tty, retries \\ 0) do
    case Nerves.UART.start_link() do
      {:ok, uart} ->
        opts = [
          active: true,
          framing: {Nerves.UART.Framing.Line, separator: "\r\n"}
        ]
        Nerves.UART.open(uart, tty, opts)
        do_fw_loop(uart, tty)
      {:error, reason} ->
        Logger.error 1, "Failed to connect to firmware for update: #{inspect reason}"
    end
  end

  defp do_wait_idle(uart, tty) do
    receive do
      {:nerves_uart, ^tty, {:error, reason}} ->
        Logger.error 1, "Failed to connect to firmware for update: #{inspect reason}"
      {:nerves_uart, ^tty, data} ->
        if String.contains?(data, "R00") do
          # tell the FW to report its version.
          Nerves.UART.write("F83")
          do_wait_version(uart, tty)
        else
          do_wait_idle(uart, tty)
        end
    after
      15_000 ->
        Logger.warn 1, "timeout waiting for firmware. Forcing flash."
    end
  end

  defp do_wait_version(uart, tty) do
    receive do
      {:nerves_uart, ^tty, {:error, reason}} ->
        Logger.error 1, "Failed to connect to firmware for update: #{inspect reason}"
      {:nerves_uart, ^tty, data} ->
        
    end
  end
end
