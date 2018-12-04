defmodule Farmbot.Firmware.UARTTransport do
  @moduledoc """
  Handles sending/receiving GCODEs over UART.
  This is the mechanism that official Farmbot's communicate with
  official Farmbot-Arduino-Firmware's over.
  """
  alias Farmbot.Firmware.GCODE
  alias Circuits.UART
  use GenServer

  def init(args) do
    device = Keyword.fetch!(args, :device)
    handle_gcode = Keyword.fetch!(args, :handle_gcode)
    {:ok, uart} = UART.start_link()
    {:ok, %{uart: uart, device: device, open: false, handle_gcode: handle_gcode}, 0}
  end

  def terminate(_, state) do
    UART.stop(state.uart)
  end

  def handle_info(:timeout, %{open: false} = state) do
    opts = [active: true, speed: 115_200, framing: {UART.Framing.Line, separator: "\r\n"}]

    case UART.open(state.uart, state.device, opts) do
      :ok -> {:noreply, %{state | open: true}}
      {:error, reason} -> {:stop, {:uart_error, reason}, state}
    end
  end

  def handle_info({:circuits_uart, _, {:error, reason}}, state) do
    {:stop, {:uart_error, reason}, state}
  end

  def handle_info({:circuits_uart, _, data}, state) when is_binary(data) do
    code = GCODE.decode(String.trim(data))
    state.handle_gcode.(code)
    {:noreply, state}
  end

  def handle_call(code, _from, state) do
    try do
      str = GCODE.encode(code)
      r = UART.write(state.uart, str)
      {:reply, r, state}
    rescue
      error -> {:reply, {:error, error}, state}
    end
  end
end
