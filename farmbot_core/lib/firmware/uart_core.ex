defmodule FarmbotCore.Firmware.UARTCore do
  @moduledoc """
  UARTCore is the topmost UART process. UARTCore handles RX/TX
  from a serial device such as a Farmduino (1.3+) or Arduino
  Mega (FarmBot v1.2).

  Guiding Principals:
   * No cached state - Delay data fetching. Never duplicate.
   * No timeouts     - Push data, don't pull.
   * No polling      - Push data, don't pull.
   * No retries      - Fail fast / hard. Restarting the module
                       is the only recovery option.

  SYSTEM DIAGRAM:

    Incoming serial data
       ▼
      ┌────────────┐
      │UARTCore    │ Top level process. If things go wrong,
      └────────────┘ restart this process.
       ▼
      ┌────────────┐ Ensures that GCode is a fully formed
      │RxBuffer    │ block.
      └────────────┘
       ▼
      ┌────────────┐ Converts GCode strings to machine readable
      │GCodeDecoder│ data structures. Crashes on bad input.
      └────────────┘
       ▼
      ┌────────────┐ Triggers callbacks as the system ingests
      │InboundGCode│ GCode
      └────────────┘

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
  alias FarmbotCore.Firmware.UARTCoreSupport, as: Support

  alias FarmbotCore.Firmware.{
    RxBuffer,
    TxBuffer,
    GCodeDecoder,
    InboundGCode
  }

  require Logger

  defstruct circuits_pid: nil,
            rx_buffer: RxBuffer.new(),
            rx_status: InboundGCode.new(),
            tx_buffer: TxBuffer.new()

  @ten_minutes 1000 * 60 * 10

  # Send raw GCode to the MCU. Blocks the calling process
  # until a response is received.
  # Don't use this function outside of the `/firmware`
  # directory.
  def start_job(server \\ __MODULE__, gcode) do
    IO.puts("Starting job #{inspect(gcode)}")
    GenServer.call(server, {:start_job, gcode}, @ten_minutes)
  end

  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(opts) do
    {:ok, circuits_pid} = Support.connect(Keyword.fetch!(opts, :path))

    {:ok, %State{circuits_pid: circuits_pid}}
  end

  # === SCENARIO: FBOS wants to send raw text to the attached
  #               serial device
  def handle_info({:send_raw, text}, state) do
    :ok = Support.uart_send(state.circuits_pid, text)
    {:noreply, state}
  end

  # === SCENARIO: Serial cable is unplugged.
  def handle_info({:circuits_uart, _, {:error, :eio}}, state) do
    {:noreply, %{state | rx_buffer: RxBuffer.new()}}
  end

  # === SCENARIO: Serial sent us some chars to consume.
  def handle_info({:circuits_uart, _, msg}, state) when is_binary(msg) do
    # First, push all messages into a buffer. The result is a
    # list of Gcode blocks to be processed (if any).
    {next_rx_buffer, txt_lines} = process_incoming_text(state.rx_buffer, msg)
    gcodes = GCodeDecoder.run(txt_lines)
    # Next, pass the list of GCode blocks to a side effect
    # handler.
    next_rx_status = InboundGCode.process(state.rx_status, gcodes)

    state_update = %{
      rx_buffer: next_rx_buffer,
      rx_status: next_rx_status
    }

    {:noreply, Map.merge(state, state_update)}
  end

  def handle_info(message, state) do
    Logger.error("UNEXPECTED FIRMWARE MESSAGE: #{inspect(message)}")
    {:noreply, state}
  end

  # Emergency stop always gets to jump the queue.
  def handle_call({:start_job, "E"}, _, state) do
    Circuits.UART.write(state.circuits_pid, " E\r\n")
    {:noreply, %{state | tx_buffer: TxBuffer.new()}}
  end

  def handle_call({:start_job, gcode}, caller_pid, state) do
    # TODO: How will I call `GenServer.reply`?
    next_buffer = TxBuffer.push(state.tx_buffer, {caller_pid, gcode})
    {:noreply, %{state | tx_buffer: next_buffer}}
  end

  defp process_incoming_text(rx_buffer, text) do
    rx_buffer
    |> RxBuffer.puts(text)
    |> RxBuffer.gets()
  end
end
