defmodule Farmbot.Firmware.UartHandler do
  @moduledoc """
  Handles communication between farmbot and uart devices
  """

  use GenStage
  alias Nerves.UART
  require Logger

  @doc """
  Writes a string to the uart line
  """
  def write(handler, string) do
    GenStage.call(handler, {:write, string}, :infinity)
  end

  @doc "Starts a UART Firmware Handler."
  def start_link(opts) do
    GenStage.start_link(__MODULE__, [], opts)
  end

  ## Private

  defmodule State do
    @moduledoc false
    defstruct [
      :nerves,
      :codes
    ]
  end

  def init([]) do
    tty = Application.get_env(:farmbot, :uart_handler)[:tty] || raise "Please configure uart handler!"
    {:ok, nerves} = UART.start_link()
    Process.link(nerves)
    case open_tty(nerves, tty) do
      :ok -> {:producer, %State{nerves: nerves, codes: []}}
      err -> {:stop, err, :no_state}
    end
  end

  defp open_tty(nerves, tty) do
    case UART.open(nerves, tty, speed: 115_200, active: true) do
      :ok ->
        :ok = configure_uart(nerves, true)
        # Flush the buffers so we start fresh
        :ok = UART.flush(nerves)
        :ok
      err -> err
    end
  end

  defp configure_uart(nerves, active) do
    UART.configure(nerves,
      framing: {UART.Framing.Line, separator: "\r\n"},
      active: active,
      rx_framing_timeout: 500)
  end

  def handle_info({:nerves_uart, _, {:error, reason}}, state) do
    {:stop, {:error, reason}, state}
  end

  def handle_info({:nerves_uart, _, {:unhandled_gcode, _code_str}}, state) do
    {:noreply, [], state}
  end

  def handle_info({:nerves_uart, _, {_q, gcode}}, state) do
    do_dispatch([gcode | state.codes], state)
  end

  def handle_call({:write, stuff}, _from, state) do
    UART.write(state.nerves, stuff)
    {:reply, :ok, [], state}
  end

  def handle_demand(_amnt, state) do
    do_dispatch(state.codes, state)
  end

  defp do_dispatch(codes, state) do
    {:noreply, Enum.reverse(codes), %{state | codes: []}}
  end

end
