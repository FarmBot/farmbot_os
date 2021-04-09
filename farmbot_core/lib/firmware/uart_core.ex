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
    GCodeDecoder,
    InboundGCode
  }

  require Logger

  defstruct circuits_pid: nil,
            rx_buffer: RxBuffer.new(),
            inbound_gcode: InboundGCode.new()

  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(opts) do
    {:ok, circuits_pid} = Support.connect(Keyword.fetch!(opts, :path))

    {:ok, %State{circuits_pid: circuits_pid}}
  end

  # === SCENARIO: Serial cable is unplugged.
  def handle_info({:circuits_uart, _, {:error, :eio}}, state) do
    {:noreply, %{state | rx_buffer: RxBuffer.new()}}
  end

  # === SCENARIO: Serial sent us some chars to consume.
  def handle_info({:circuits_uart, _, msg}, state) when is_binary(msg) do
    # First, push all messages into a buffer. The result is a
    # list of Gcode blocks to be processed (if any).
    {next_rx_buffer, gcodes} = process_incoming_text(state.rx_buffer, msg)

    # Next, pass the list of GCode blocks to a side effect
    # handler.
    next_inbound_gcode = InboundGCode.process(state.inbound_gcode, gcodes)

    state_update = %{
      rx_buffer: next_rx_buffer,
      inbound_gcode: next_inbound_gcode
    }

    {:noreply, Map.merge(state, state_update)}
  end

  def handle_info(message, state) do
    Logger.error("UNEXPECTED FIRMWARE MESSAGE: #{inspect(message)}")
    {:noreply, state}
  end

  defp process_incoming_text(rx_buffer, text) do
    rx_buffer
    |> RxBuffer.puts(text)
    |> RxBuffer.gets()
    |> GCodeDecoder.run()
  end
end
