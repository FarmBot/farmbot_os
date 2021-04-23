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
      ┌──────────────────┐ Triggers callbacks as the system ingests
      │InboundSideEffects│ GCode
      └──────────────────┘

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
    InboundSideEffects
  }

  require Logger

  defstruct circuits_pid: nil,
            rx_buffer: RxBuffer.new(),
            tx_buffer: TxBuffer.new(),
            # Is the device emergency locked?
            locked: false,
            # Has the MCU received a valid firmware
            # config from FBOS?
            config_phase: :not_started

  @ten_minutes 1000 * 60 * 10

  # Schedule GCode to the MCU using the job queue. Blocks
  # the calling process until a response is received. Don't
  # use this function outside of the `/firmware` directory.
  def start_job(server \\ __MODULE__, gcode) do
    GenServer.call(server, {:start_job, gcode}, @ten_minutes)
  end

  # Sends GCode directly to the MCU without any checks or
  # queues. Don't use outside of the `/firmware` directory.
  def send_raw(server \\ __MODULE__, gcode) do
    send(server, {:send_raw, gcode})
  end

  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(opts) do
    {:ok, circuits_pid} = Support.connect(Keyword.fetch!(opts, :path))
    {:ok, %State{circuits_pid: circuits_pid}}
  end

  # === SCENARIO: EMERGENCY LOCK - this one gets special
  # treatment. It skips all queing mechanisms and dumps
  # any tasks that were already queued.
  def handle_info({:send_raw, "E"}, state) do
    Circuits.UART.write(state.circuits_pid, "E\r\n")
    {:noreply, %{state | tx_buffer: TxBuffer.new(), locked: true}}
  end

  # === SCENARIO: Direct GCode transmission without queueing
  def handle_info({:send_raw, text}, state) do
    IO.puts(" == SEND RAW: #{inspect(text)}")
    # TODO: Use `Support.uart_send`.
    Circuits.UART.write(state.circuits_pid, "#{text}\r\n")
    {:noreply, state}
  end

  # === SCENARIO: Serial cable is unplugged.
  def handle_info({:circuits_uart, _, {:error, :eio}}, state) do
    {:noreply, %{state | rx_buffer: RxBuffer.new()}}
  end

  # === SCENARIO: Serial sent us some chars to consume.
  def handle_info({:circuits_uart, _, msg}, state1) when is_binary(msg) do
    # First, push all messages into a buffer. The result is a
    # list of stringly-typed Gcode blocks to be
    # processed (if any).
    {next_rx_buffer, txt_lines} = process_incoming_text(state1.rx_buffer, msg)
    state2 = %{state1 | rx_buffer: next_rx_buffer}
    # Then, format GCode strings into Elixir-readable tuples.
    gcodes = GCodeDecoder.run(txt_lines)
    # Lastly, trigger any relevant side effect(s).
    # Example: send userl logs when firmware is locked.
    state3 = InboundSideEffects.process(state2, gcodes)

    {:noreply, state3}
  end

  # === SCENARIO: Unexpected message from a library or FBOS.
  def handle_info(message, state) do
    Logger.error("UNEXPECTED FIRMWARE MESSAGE: #{inspect(message)}")
    {:noreply, state}
  end

  def handle_call({:start_job, gcode}, caller, %{locked: false} = state) do
    next_buffer = TxBuffer.push(state.tx_buffer, {caller, gcode})
    IO.puts("TODO: Add semaphore to avoid race conditions??")

    next_state =
      TxBuffer.process_next_message(%{state | tx_buffer: next_buffer})

    {:noreply, next_state}
  end

  # Always reject job requests if locked != false.
  def handle_call({:start_job, _gcode}, _, state) do
    {:reply, {:error, "Device is locked."}, state}
  end

  defp process_incoming_text(rx_buffer, text) do
    rx_buffer
    |> RxBuffer.puts(text)
    |> RxBuffer.gets()
  end
end
