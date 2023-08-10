defmodule FarmbotOS.Firmware.UARTCore do
  @moduledoc """
  UARTCore is the central logic and processing module for all
  inbound and outbound UART data (GCode).

  Guiding Principles:
   * No cached state - Delay data fetching. Never duplicate.
   * No timeouts     - Push data, don't pull.
   * No polling      - Push data, don't pull.
   * No retries      - Fail fast / hard. Restarting the module
                       is the only recovery option.
  """

  alias __MODULE__, as: State
  alias FarmbotOS.Firmware.UARTCoreSupport, as: Support
  alias FarmbotOS.BotState

  alias FarmbotOS.Firmware.{
    RxBuffer,
    TxBuffer,
    GCodeDecoder,
    InboundSideEffects
  }

  alias FarmbotOS.BotState.JobProgress.Percent

  require Logger
  require FarmbotOS.Logger

  defstruct uart_pid: nil,
            logs_enabled: false,
            uart_path: nil,
            needs_config: true,
            fw_type: nil,
            rx_count: 0,
            rx_buffer: RxBuffer.new(),
            tx_buffer: TxBuffer.new(),
            pin_watcher: nil,
            red_led_pid: nil

  # The Firmware has a 120 second default timeout.
  # Queuing up 10 messages that take one minute each == 10 minutes.
  # This is a reasonable (but not perfect) assumption. RC
  @minutes 10
  @fw_timeout 1000 * 60 * @minutes

  # ==== HISTORICAL NOTE ABOUT FBExpress 1.0 ===============
  # Unlike USB serial ports, FBExpress serial uses GPIO.
  # This means the GPIO is always running with no definitive
  # start/stop signal. This means the parser gets "stuck" on
  # the wrong GCode block. The end result is a firmware handler
  # that sits there and does nothing. To get around this,
  # we do a "health check" after a certain amount of time to
  # ensure the farmduino is actually running.
  @bugfix_timeout 60_000
  # ===== END HISTORICAL CODE ==============================

  def watch_pin(server \\ __MODULE__, pin_number) do
    send(server, {:watch_pin, self()})
    FarmbotOS.Firmware.Command.watch_pin(pin_number)
  end

  def unwatch_pin(server \\ __MODULE__) do
    send(server, :unwatch_pin)
    FarmbotOS.Firmware.Command.watch_pin(0)
  end

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
    GenServer.call(server, {:flash_firmware, package}, @fw_timeout)
  end

  def start_job(server \\ __MODULE__, gcode) do
    GenServer.call(server, {:start_job, gcode}, @fw_timeout)
  end

  # Sends GCode directly to the MCU without any checks or
  # queues. Don't use outside of the `/firmware` directory.
  def send_raw(server \\ __MODULE__, gcode) do
    send(server, {:send_raw, gcode})
  end

  def restart_firmware(server \\ __MODULE__) do
    send(server, :reset_state)
    :ok
  end

  defp initiate_sequence_on_boot() do
    Task.Supervisor.start_child(
      FarmbotOS.Task.Supervisor,
      FarmbotOS.SequenceOnBoot,
      :schedule_boot_sequence,
      []
    )
  end

  # ================= BEGIN GENSERVER CODE =================

  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(opts) do
    BotState.firmware_offline()
    path = Keyword.fetch!(opts, :path)
    {:ok, uart_pid} = Support.connect(path)
    fw_type = Keyword.get(opts, :fw_package)
    state = %State{uart_pid: uart_pid, uart_path: path, fw_type: fw_type}
    Process.send_after(self(), :best_effort_bug_fix, @bugfix_timeout)
    {:ok, state}
  end

  def handle_info({:watch_pin, watcher}, state) do
    # if state.pin_watcher, do: raise("Pin observer did not cleanly exit!")
    {:noreply, Map.put(state, :pin_watcher, watcher)}
  end

  def handle_info(:unwatch_pin, state) do
    {:noreply, Map.put(state, :pin_watcher, nil)}
  end

  def handle_info(:reset_state, %State{uart_path: old_path} = state1) do
    # Teardown existing connection.
    Support.disconnect(state1, "Rebooting firmware")
    # Reset state tree
    {:ok, next_state} = init(path: old_path, fw_type: state1.fw_type)
    Logger.debug("Firmware restart initiated")
    {:noreply, next_state}
  end

  # === SCENARIO: EMERGENCY LOCK - this one gets special
  # treatment. It skips all queueing mechanisms and dumps
  # any tasks that were already queued.
  def handle_info({:send_raw, "E"}, %State{} = state) do
    Support.uart_send(state.uart_pid, "E")
    msg = "Emergency locked"
    txb = TxBuffer.error_all(state.tx_buffer, msg)
    Support.lock!()
    {:noreply, %{state | tx_buffer: txb}}
  end

  # === SCENARIO: Direct GCode transmission without queueing
  def handle_info({:send_raw, text}, %State{} = state) do
    Support.uart_send(state.uart_pid, text)
    {:noreply, state}
  end

  # === SCENARIO: Serial cable is unplugged.
  def handle_info({:circuits_uart, _, {:error, :eio}}, _) do
    {:stop, :cable_unplugged, %State{}}
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
    # Example: send user logs when firmware is locked.
    state3 = InboundSideEffects.process(state2, gcodes)

    if state3.needs_config && state3.rx_buffer.ready do
      Logger.debug("=== Uploading configuration")
      {:noreply, FarmbotOS.Firmware.ConfigUploader.upload(state3)}
    else
      {:noreply, state3}
    end
  end

  # === SCENARIO: Serial sent us some chars to consume.
  def handle_info({:circuits_uart, _, {:partial, msg}}, state) do
    FarmbotOS.Logger.error(3, "UART timeout: #{inspect(msg)}")
    {:noreply, state}
  end

  def handle_info({:refresh_config, new_keys}, state) do
    {:noreply, FarmbotOS.Firmware.ConfigUploader.refresh(state, new_keys)}
  end

  def handle_info(:toggle_logging, state) do
    next_state = %{state | logs_enabled: !state.logs_enabled}
    {:noreply, next_state}
  end

  def handle_info(:best_effort_bug_fix, state) do
    silent = state.rx_count < 1
    borked = BotState.fetch().informational_settings.firmware_version == nil

    if silent || borked do
      msg = "Rebooting inactive Farmduino. #{Support.uptime_ms()}"
      FarmbotOS.Logger.debug(3, msg)

      package =
        state.fw_type ||
          FarmbotOS.Asset.fbos_config().firmware_hardware

      spawn(__MODULE__, :flash_firmware, [self(), package])
    else
      FarmbotOS.Logger.debug(3, "Farmduino OK")
      set_boot_progress(%Percent{status: "Complete", percent: 100})
      initiate_sequence_on_boot()
    end

    {:noreply, state}
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
      next_buffer =
        state.tx_buffer
        |> TxBuffer.push(caller, gcode)
        |> TxBuffer.process_next_message(state.uart_pid)

      next_state = %{state | tx_buffer: next_buffer}

      {:noreply, next_state}
    end
  end

  def handle_call({:flash_firmware, nil}, _, %State{} = state) do
    msg = "Can't flash firmware yet because hardware is unknown."
    FarmbotOS.Logger.info(1, msg)
    {:reply, :ok, state}
  end

  def handle_call({:flash_firmware, package}, _, %State{} = state) do
    next_state = FarmbotOS.Firmware.Flash.run(state, package)
    Process.send_after(self(), :reset_state, 1)
    {:reply, :ok, next_state}
  end

  def terminate(_, _) do
    Logger.debug("Firmware terminated.")
    BotState.firmware_offline()
  end

  defp set_boot_progress(percent) do
    percent2 = Map.put(percent, :type, "boot")
    BotState.set_job_progress("Booting", percent2)
  end

  defp process_incoming_text(rx_buffer, text) do
    rx_buffer
    |> RxBuffer.puts(text)
    |> RxBuffer.gets()
  end
end
