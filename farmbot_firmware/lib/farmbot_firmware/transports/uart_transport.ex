defmodule Farmbot.Firmware.UARTTransport do
  alias Farmbot.Firmware.GCODE
  use GenServer

  def init(args) do
    device = Keyword.fetch!(args, :device)
    handle_gcode = Keyword.fetch!(args, :handle_gcode)
    {:ok, uart} = Nerves.UART.start_link()
    {:ok, %{uart: uart, device: device, open: false, handle_gcode: handle_gcode}, 0}
  end

  def terminate(_, state) do
    Nerves.UART.stop(state.uart)
  end

  def handle_info(:timeout, %{open: false} = state) do
    opts = [active: true, speed: 115_200, framing: {Nerves.UART.Framing.Line, separator: "\r\n"}]

    case Nerves.UART.open(state.uart, state.device, opts) do
      :ok -> {:noreply, %{state | open: true}}
      {:error, reason} -> {:stop, {:uart_error, reason}, state}
    end
  end

  def handle_info({:nerves_uart, _, {:error, reason}}, state) do
    {:stop, {:uart_error, reason}, state}
  end

  def handle_info({:nerves_uart, _, data}, state) when is_binary(data) do
    code = GCODE.decode(String.trim(data))
    state.handle_gcode.(code)
    {:noreply, state}
  end

  def handle_call(code, _from, state) do
    str = GCODE.encode(code)
    r = Nerves.UART.write(state.uart, str)
    {:reply, r, state}
  end
end
