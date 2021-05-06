defmodule FarmbotCore.Firmware.UARTCoreSupport do
  require Logger

  defstruct path: "null", uart_pid: nil
  alias FarmbotCore.BotState

  @default_opts [
    active: true,
    speed: 115_200
    # framing: Circuits.UART.Framing.FourByte,
    # rx_framing_timeout: 200
  ]

  def connect(path) do
    {:ok, pid} = Circuits.UART.start_link()
    maybe_open_uart_device(pid, path)
  end

  # Returns the uart path of the device that was disconnected
  def disconnect(%{uart_pid: pid, uart_path: tty} = state, reason) do
    # Genserer.reply to everyone with {:error, reason}
    FarmbotCore.Firmware.TxBuffer.error_all(state.tx_buffer, reason)

    if Process.alive?(pid) do
      Circuits.UART.stop(state.uart_pid)
    else
      Logger.debug("==== TRIED TO STOP UART PID BUT IT IS ALREADY DEAD")
    end

    {:ok, tty}
  end

  def uart_send(uart_pid, text) do
    Logger.info(" == SEND RAW: #{inspect(text)}")
    :ok = Circuits.UART.write(uart_pid, text <> "\r\n")
  end

  def lock!(), do: BotState.set_firmware_locked()
  def unlock!(), do: BotState.set_firmware_unlocked()
  def locked?(), do: BotState.fetch().informational_settings.locked
  # This wrapper exists only because it felt strange to mock
  # GenServer.reply/2
  def reply(caller, resp), do: GenServer.reply(caller, resp)

  def enumerate(), do: Circuits.UART.enumerate()

  def device_available?(path) do
    Map.has_key?(enumerate(), path)
  end

  defp maybe_open_uart_device(pid, path) do
    if device_available?(path) do
      open_uart_device(pid, path)
    else
      {:error, :device_not_available}
    end
  end

  defp open_uart_device(pid, path) do
    :ok = Circuits.UART.open(pid, path, @default_opts)
    {:ok, pid}
  end
end
