defmodule FarmbotFirmware.UartDefaultAdapter do
  @moduledoc """
  A thin wrapper of Circuits.UART to simplify testing.
  """
  # defdelegate start_link, to: Circuits.UART, as: :start_link
  # defdelegate open(uart_pid, device_path, opts), to: Circuits.UART, as: :open
  # defdelegate stop(uart_pid), to: Circuits.UART, as: :stop
  # defdelegate write(uart_pid, str), to: Circuits.UART, as: :write

  # ========= STUB!!!
  def open(_, _, _) do
    :ok
  end

  # ========= STUB!!!
  def write(_, _) do
    :ok
  end

  def generate_opts do
    [
      active: true,
      speed: 115_200,
      framing: {Circuits.UART.Framing.Line, separator: "\r\n"}
    ]
  end
end
