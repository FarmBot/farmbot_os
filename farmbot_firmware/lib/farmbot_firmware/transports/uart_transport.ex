defmodule FarmbotFirmware.UARTTransport do
  @moduledoc """
  Handles sending/receiving GCODEs over UART.
  This is the mechanism that official Farmbot's communicate with
  official Farmbot-Arduino-Firmware's over.
  """
  alias FarmbotFirmware.GCODE
  alias Circuits.UART
  use GenServer
  require Logger

  @error_retry_ms 5_000

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

    with :ok <- open(state.uart, state.device, opts),
         :ok <- reset(state.uart, state.device, opts) do
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
    r = UART.write(state.uart, str)
    {:reply, r, state}
  end

  def reset(_uart_pid, _device_path, _opts) do
    if module = config()[:reset] do
      module.reset()
    else
      :ok
    end
  end

  def open(uart_pid, device_path, opts) do
    UART.open(uart_pid, device_path, opts)
  end

  defp config do
    Application.get_env(:farmbot_firmware, __MODULE__)
  end
end
