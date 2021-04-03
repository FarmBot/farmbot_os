defmodule FarmbotCore.Firmware.UARTSupport do
  defstruct path: "null", circuits_pid: nil
  @default_opts [speed: 115_200, active: true]

  def connect(pid) do
    GenServer.call(pid, :connect, :infinity)
  end

  def maybe_open_uart_device(pid, path) do
    if device_available?(path) do
      open_uart_device(pid, path)
    else
      {:error, :device_not_available}
    end
  end

  defp open_uart_device(pid, path) do
    Circuits.UART.open(pid, path, @default_opts)
  end

  defp device_available?(path) do
    Map.has_key?(Circuits.UART.enumerate(), path)
  end
end
