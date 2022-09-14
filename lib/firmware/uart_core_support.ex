defmodule FarmbotOS.Firmware.UARTCoreSupport do
  require Logger

  defstruct path: "null", uart_pid: nil
  alias FarmbotOS.BotState

  @default_opts [
    active: true,
    speed: 57_600,
    framing: {Circuits.UART.Framing.Line, separator: "\r\n"},
    rx_framing_timeout: 600
  ]
  @three_minutes 3 * 60 * 1000

  def uptime_ms() do
    {ms, _} = :erlang.statistics(:wall_clock)
    ms
  end

  # This is a heuristic, but probably good enough given the
  # requirements.
  #
  # PROBLEM:  We need to flash the Arduino firmware every
  #           boot, if possible, but not every time a GenServer
  #           restarts (an arduino can be flashed ~10,000
  #           times according to spec).
  #
  # SOLUTION: Just check the system uptime instead of
  #           maintaining a process to track that state.
  def recent_boot?() do
    uptime_ms() < @three_minutes
  end

  def connect(path) do
    {:ok, pid} = Circuits.UART.start_link()
    maybe_open_uart_device(pid, path)
  end

  # Returns the uart path of the device that was disconnected
  def disconnect(%{uart_path: tty} = state, reason) do
    # Genserver.reply to everyone with {:error, reason}
    FarmbotOS.Firmware.TxBuffer.error_all(state.tx_buffer, reason)
    uart = state.uart_pid

    if is_pid(uart) && Process.alive?(uart) do
      Circuits.UART.close(uart)
      Circuits.UART.stop(uart)
    end

    {:ok, tty}
  end

  def uart_send(uart_pid, text) do
    #   Logger.info(" == SEND RAW: #{inspect(text)}")
    :ok = Circuits.UART.write(uart_pid, text)
  end

  def lock!(), do: BotState.set_firmware_locked()
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
