defmodule FarmbotCore.Firmware.UARTCore do
  @moduledoc """
  UARTCore is the topmost UART process. UARTCore handles RX/TX
  from a serial device such as a Farmduino (1.3+) or Arduino
  Mega (FarmBot v1.2).

  Guiding Principles:
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
  require FarmbotCore.Logger

  defstruct circuits_pid: nil,
            logs_enabled: false,
            uart_path: nil,
            # Has the MCU received a valid firmware
            # config from FBOS?
            config_phase: :not_started,
            rx_buffer: RxBuffer.new(),
            tx_buffer: TxBuffer.new()

  # The Firmware has a 120 second default timeout.
  # Queuing up 10 messages that take one minute each == 10 minutes.
  # This is a reasonable (but not perfect) assumption. RC
  @minutes 10
  @fw_timeout 1000 * 60 * @minutes

  # This is a helper method that I use for inspecting GCode
  # over SSH. It is not used by production systems except for
  # debugging.
  def toggle_logging(server \\ __MODULE__) do
    send(server, :toggle_logging)
  end

  def refresh_config(server, new_keys) do
    send(server, {:refresh_config, new_keys})
  end

  def flash_firmware(server \\ __MODULE__, package) do
    Logger.info("Begin firmware flash (#{inspect(package)})")
    GenServer.call(server, {:flash_firmware, package}, @fw_timeout)
  end

  # Schedule GCode to the MCU using the job queue. Blocks
  # the calling process until a response is received. Don't
  # use this function outside of the `/firmware` directory.
  def start_job(server \\ __MODULE__, gcode) do
    Logger.info("Scheduling #{inspect(gcode)}")
    GenServer.call(server, {:start_job, gcode}, @fw_timeout)
  end

  # Sends GCode directly to the MCU without any checks or
  # queues. Don't use outside of the `/firmware` directory.
  def send_raw(server \\ __MODULE__, gcode) do
    send(server, {:send_raw, gcode})
  end

  def restart_firmware(server \\ __MODULE__) do
    send(server, :restart_firmware)
    :ok
  end

  # ================= BEGIN GENSERVER CODE =================

  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(opts) do
    FarmbotCore.BotState.firmware_offline()
    path = Keyword.fetch!(opts, :path)
    {:ok, circuits_pid} = Support.connect(path)
    {:ok, %State{circuits_pid: circuits_pid, uart_path: path}}
  end

  def handle_info(:restart_firmware, %State{uart_path: old_path} = state1) do
    # Teardown existing connection.
    Support.disconnect(state1, "Rebooting firmware")
    # Reset state tree
    {:ok, next_state} = init(path: old_path)
    FarmbotCore.Logger.info(1, "Firmware restart initiated")
    {:noreply, next_state}
  end

  # === SCENARIO: EMERGENCY LOCK - this one gets special
  # treatment. It skips all queing mechanisms and dumps
  # any tasks that were already queued.
  def handle_info({:send_raw, "E"}, %State{} = state) do
    Support.uart_send(state.circuits_pid, "E\r\n")
    TxBuffer.error_all(state, "Emergency locked")
    Support.lock!()
    {:noreply, %{state | tx_buffer: TxBuffer.new()}}
  end

  # === SCENARIO: Direct GCode transmission without queueing
  def handle_info({:send_raw, text}, %State{} = state) do
    Support.uart_send(state.circuits_pid, "#{text}\r\n")
    {:noreply, state}
  end

  # === SCENARIO: Serial cable is unplugged.
  def handle_info({:circuits_uart, _, {:error, :eio}}, %State{} = state) do
    {:noreply, %{state | rx_buffer: RxBuffer.new()}}
  end

  # === SCENARIO: Serial sent us some chars to consume.
  def handle_info({:circuits_uart, _, msg}, %State{} = state1)
      when is_binary(msg) do
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

  def handle_info({:refresh_config, new_keys}, state) do
    {:noreply, FarmbotCore.Firmware.ConfigUploader.refresh(state, new_keys)}
  end

  def handle_info(:toggle_logging, state) do
    next_state = %{state | logs_enabled: !state.logs_enabled}
    {:noreply, next_state}
  end

  # === SCENARIO: Unexpected message from a library or FBOS.
  def handle_info(message, %State{} = state) do
    Logger.error("UNEXPECTED FIRMWARE MESSAGE: #{inspect(message)}")
    {:noreply, state}
  end

  def handle_call({:start_job, gcode}, caller, %State{} = state) do
    if Support.locked?() do
      {:reply, {:error, "Device is locked."}, state}
    else
      next_buffer = TxBuffer.push(state.tx_buffer, {caller, gcode})

      next_state =
        TxBuffer.process_next_message(%{state | tx_buffer: next_buffer})

      {:noreply, next_state}
    end
  end

  def handle_call({:flash_firmware, package}, _, %State{} = state) do
    next_state = FarmbotCore.Firmware.Flash.run(state, package)
    Process.send_after(self(), :restart_firmware, 1)
    {:reply, :ok, next_state}
  end

  def terminate(_, _) do
    Logger.debug("Firmware terminated.")
    FarmbotCore.BotState.firmware_offline()
  end

  defp process_incoming_text(rx_buffer, text) do
    rx_buffer
    |> RxBuffer.puts(text)
    |> RxBuffer.gets()
  end
end
