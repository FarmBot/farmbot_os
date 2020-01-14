defmodule FarmbotFirmware.UartDefaultAdapter do
  @moduledoc """
  A thin wrapper of Circuits.UART to simplify testing.
  """
  alias Circuits.UART
  @behaviour FarmbotFirmware.UartAdapter

  @impl FarmbotFirmware.UartAdapter
  def start_link do
    UART.start_link()
  end

  @impl FarmbotFirmware.UartAdapter
  def open(uart_pid, device_path, opts) do
    UART.open(uart_pid, device_path, opts)
  end

  @impl FarmbotFirmware.UartAdapter
  def stop(uart_pid) do
    IO.puts("Hello?")
    UART.stop(uart_pid)
  end

  @impl FarmbotFirmware.UartAdapter
  def write(uart_pid, str) do
    UART.write(uart_pid, str)
  end

  @impl FarmbotFirmware.UartAdapter
  def generate_opts do
    [
      active: true,
      speed: 115_200,
      framing: {UART.Framing.Line, separator: "\r\n"}
    ]
  end
end
