defmodule Farmbot.Firmware.UartHandler do
  @moduledoc """
  Handles communication between farmbot and uart devices
  """

  use GenServer
  alias Nerves.UART
  alias Farmbot.Firmware.Gcode.Parser
  require Logger

  @default_timeout_ms 15_000

  @doc """
  Writes a string to the uart line
  """
  def write(handler, string) do
    GenServer.call(handler, {:write, string, @default_timeout_ms}, :infinity)
  end

  @doc "Starts a UART GenServer"
  def start_link(firmware, opts) do
    GenServer.start_link(__MODULE__, firmware, opts)
  end

  ## Private

  defmodule State do
    @moduledoc false
    defstruct [
      :firmware,
      :nerves
    ]
  end

  def init(firmware) do
    tty = Application.get_env(:farmbot, :uart_handler)[:tty] || raise "Please configure uart handler!"
    {:ok, nerves} = UART.start_link()
    Process.link(nerves)
    case open_tty(nerves, tty) do
      :ok -> {:ok, %State{firmware: firmware, nerves: nerves}}
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

  def handle_info({:nerves_uart, _, bin}, state) do
    case Parser.parse_code(bin) do
      {:unhandled_gcode, code_str} ->
        Logger.warn "Got unhandled code: #{code_str}"
      {_q, gcode} ->
        _reply = Farmbot.Firmware.handle_gcode(state.firmware, gcode)
    end
    {:noreply, state}
  end

end
