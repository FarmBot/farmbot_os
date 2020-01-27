defmodule FarmbotFirmware.UARTTransport do
  @moduledoc """
  Handles sending/receiving GCODEs over UART.
  This is the mechanism that official Farmbot's communicate with
  official Farmbot-Arduino-Firmware's over.
  """
  alias FarmbotFirmware.{GCODE, UartDefaultAdapter}
  use GenServer
  require Logger

  @error_retry_ms 5_000

  def init(args) do
    device = Keyword.fetch!(args, :device)
    handle_gcode = Keyword.fetch!(args, :handle_gcode)
    reset = Keyword.get(args, :reset)
    {:ok, uart} = uart_adapter().start_link()

    {:ok,
     %{
       uart: uart,
       device: device,
       open: false,
       handle_gcode: handle_gcode,
       reset: reset
     }, 0}
  end

  def terminate(_, %{uart: uart}) do
    uart_adapter().stop(uart)
  end

  def handle_info(:timeout, %{open: false} = state) do
    opts = uart_adapter().generate_opts()

    with :ok <- open(state.uart, state.device, opts),
         :ok <- reset(state) do
      {:noreply, %{state | open: true}}
    else
      {:error, reason} ->
        Logger.error("Error opening #{state.device}: #{inspect(reason)}")
        {:noreply, %{state | open: false}, @error_retry_ms}
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
    str = GCODE.encode(code)
    r = uart_adapter().write(state.uart, str)
    {:reply, r, state}
  end

  def reset(state) do
    if module = state[:reset] do
      module.reset()
    else
      :ok
    end
  end

  def open(uart_pid, device_path, opts) do
    uart_adapter().open(uart_pid, device_path, opts)
  end

  def uart_adapter() do
    UartDefaultAdapter
  end
end
