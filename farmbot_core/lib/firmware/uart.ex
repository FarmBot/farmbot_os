defmodule FarmbotCore.Firmware.UART do
  @moduledoc """
  The UARTController handles RX/TX from a serial device
  such as a Farmduino (1.3+) or Arduino Mega (FarmBot v1.2).

  Guiding Principals:
   * No cached state
   * No timeouts
   * No retries
   * No polling

  Callbacks required:
   * New message (UART -> App)
   * Disconnect
   * Reconnect

  Functionality:
   * Open serial
   * Close serial

  Things that can go wrong:
   * `path` changes
   * disconnect
  """

  alias __MODULE__, as: State
  alias FarmbotCore.Firmware.UARTSupport, as: Support
  alias FarmbotCore.Firmware.LineBuffer

  defstruct path: "null", circuits_pid: nil, parser: LineBuffer.new()

  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(opts) do
    {:ok, circuits_pid} = Circuits.UART.start_link()

    state = %State{
      path: Keyword.fetch!(opts, :path),
      circuits_pid: circuits_pid
    }

    {:ok, state}
  end

  def handle_call(:connect, _, state) do
    %{circuits_pid: pid, path: path} = state
    result = Support.maybe_open_uart_device(pid, path)
    {:reply, result, state}
  end

  # === SCENARIO: Serial cable is unplugged.
  def handle_info({:circuits_uart, _, {:error, :eio}}, state) do
    {:noreply, %{state | parser: LineBuffer.new()}}
  end

  # === SCENARIO: Serial sent us some chars to consume.
  def handle_info({:circuits_uart, _, msg}, state) do
    {next_parser, _tokens} =
      state.parser
      |> LineBuffer.puts(msg)
      |> LineBuffer.gets()

    {:noreply, %{state | parser: next_parser}}
  end

  def handle_info(message, state) do
    IO.puts("!!! UNEXPECTED MESSAGE: #{inspect(message)}")
    {:noreply, state}
  end
end
