defmodule FarmbotCore.Firmware.UARTCoreSupport do
  defstruct path: "null", circuits_pid: nil
  @default_opts [speed: 115_200, active: true]

  def connect(path) do
    {:ok, pid} = Circuits.UART.start_link()
    maybe_open_uart_device(pid, path)
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

  defp device_available?(path) do
    Map.has_key?(Circuits.UART.enumerate(), path)
  end
end
