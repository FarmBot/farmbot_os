defmodule FarmbotFirmware.UartDefaultAdapter do
  @moduledoc """
  A thin wrapper of Circuits.UART to simplify testing.
  """
  alias Circuits.UART

  def start_link do
    UART.start_link()
  end

  def open(uart_pid, device_path, opts) do
    UART.open(uart_pid, device_path, opts)
  end

  def stop(uart_pid) do
    UART.stop(uart_pid)
  end

  def write(uart_pid, str) do
    UART.write(uart_pid, str)
  end

  def generate_opts do
    [
      active: true,
      speed: 115_200,
      framing: {UART.Framing.Line, separator: "\r\n"}
    ]
  end
end
