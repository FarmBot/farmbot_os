defmodule FarmbotFirmware.UartTestAdapter do
  @behaviour FarmbotFirmware.UartAdapter

  @impl FarmbotFirmware.UartAdapter
  def start_link() do
    # UART.start_link()
    raise("WIP")
  end

  @impl FarmbotFirmware.UartAdapter
  def stop(uart_pid) do
    # UART.stop(uart_pid)
    raise("WIP")
  end

  @impl FarmbotFirmware.UartAdapter
  def write(uart_pid, str) do
    # UART.write(uart_pid, str)
    raise("WIP")
  end

  @impl FarmbotFirmware.UartAdapter
  def generate_opts(), do: []
end
