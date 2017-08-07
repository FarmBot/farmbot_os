defmodule Farmbot.Serial.Handler do
  @moduledoc """
    Handles communication between farmbot and uart devices
  """

  alias Farmbot.BotState
  alias Farmbot.Context
  alias Farmbot.Lib.Maths
  alias Farmbot.Serial.Gcode.Parser
  alias Nerves.UART
  require Logger
  use GenServer

  # use Farmbot.DebugLog, enable: false
  use Farmbot.DebugLog

  @typedoc """
    Handler pid or name
  """
  @type handler :: pid | atom

  @typedoc """
    Nerves.UART pid or name
  """
  @type nerves :: handler

  @typedoc """
    Status of the arduino
  """
  @type status :: :busy | :done

  @typedoc """
    State for this GenServer
  """
  @type state :: %{
    context: Context.t,
    nerves: nerves,
    tty: binary,
    current: current,
    timeouts: integer,
    status: status,
    initialized: boolean
  }

  @typedoc """
    The current message being handled
  """
  @type current :: %{
    timer: reference,
    reply: tuple,
    status: status,
    from: {pid, reference},
    q: binary
  } | nil

  @default_timeout_ms 15_000
  @max_timeouts 10

  @doc """
    Starts a UART GenServer
  """
  def start_link(%Context{} = ctx, nerves, tty, opts)
  when is_pid(nerves) and is_binary(tty) do
    GenServer.start_link(__MODULE__, {ctx, nerves, tty}, opts)
  end

  def start_link(%Context{} = ctx, tty, opts) when is_binary(tty) do
    GenServer.start_link(__MODULE__, {ctx, tty}, opts)
  end

  @doc """
  Blocks the calling process until serial is ready.
  """
  @spec wait_for_available(Context.t) :: :ok | {:error, term}
  def wait_for_available(%Context{serial: handler} = context)
    when is_atom(handler)
  do
    pid = Process.whereis(handler)
    if is_pid(pid) and Process.alive?(pid) do
      new = %{context | serial: pid}
      wait_for_available(new)
    else
      {:error, :noproc}
    end
  end

  def wait_for_available(%Context{serial: handler}) do
    GenServer.call(handler, :wait_for_available, 12_000)
  end

  @doc """
  Checks if we have a handler available
  """
  @spec available?(Context.t) :: boolean
  def available?(context)

  # If handler is a pid
  def available?(%Context{serial: handler}) when is_pid(handler) do
    if Process.alive?(handler) do
      GenServer.call(handler, :available?)
    else
      false
    end
  end

  # if its a name, look it up
  def available?(%Context{serial: handler} = ctx) when is_atom(handler) do
    uh = Process.whereis(ctx.serial)
    if uh do
      available?(%{ctx | serial: uh})
    else
      false
    end
  end

  @doc """
    Writes a string to the uart line
  """
  @spec write(Context.t, binary, integer) :: binary | {:error, atom}
  def write(context, string, timeout \\ @default_timeout_ms)
  def write(%Context{} = ctx, str, timeout)
  when is_binary(str) and is_number(timeout) do
    if available?(ctx) do
      # try do
      #   fn() -> debug_log("write begin from: #{inspect Process.info(self())}") end.()
      # rescue
      #   _ -> :ok
      # end
      GenServer.call(ctx.serial, {:write, str, timeout}, :infinity)
    else
      {:error, :unavailable}
    end
  end

  @doc """
    Send the E stop command to the arduino.
  """
  @spec emergency_lock(Context.t) :: :ok | no_return
  def emergency_lock(%Context{} = ctx) do
    if available?(ctx) do
      GenServer.call(ctx.serial, :emergency_lock)
    else
      {:error, :unavailable}
    end
  end

  @doc """
    Tell the arduino its fine now.
  """
  @spec emergency_unlock(Context.t) :: :ok | no_return
  def emergency_unlock(%Context{} = ctx)  do
    # We check for aliveness here, not availableness.
    if is_alive?(ctx) do
      GenServer.call(ctx.serial, :emergency_unlock)
    else
      {:error, :unavailable}
    end
  end

  defp is_alive?(%Context{serial: serial}) when is_pid(serial) do
    Process.alive?(serial)
  end

  defp is_alive?(%Context{serial: serial} = ctx) when is_atom(serial) do
    pid = Process.whereis(serial)
    if pid do
      is_alive?(%{ctx | serial: pid})
    else
      false
    end
  end

  ## Private

  def init({ctx, nerves, tty}) when is_pid(nerves) and is_binary(tty) do
    Process.link(nerves)
    case open_tty(nerves, tty) do
      :ok ->
        state = %{
          context:     ctx,
          nerves:      nerves,
          tty:         tty,
          current:     nil,
          timeouts:    0,
          status:      :busy,
          waiting:     [],
          initialized: false
        }
        {:ok, state}
      err   ->
        debug_log "could not open tty: #{inspect err}"
        {:stop, :normal, :no_state}
    end
  end

  def init({ctx, tty}) when is_binary(tty) do
    {:ok, nerves} = UART.start_link()
    init({ctx, nerves, tty})
  end

  @spec open_tty(nerves, binary) :: :ok
  defp open_tty(nerves, tty) do
    # Open the tty
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
    debug_log "reconfigureing uart: #{active}"
    UART.configure(nerves,
      framing: {UART.Framing.Line, separator: "\r\n"},
      active: active,
      rx_framing_timeout: 500)
  end

  def handle_call(:wait_for_available, from, state) do
    case state.status do
      :idle   -> {:reply, :ok,               state}
      :locked -> {:reply, {:error, :locked}, state}
      _       ->
        Process.send_after(self(), {:waiting_timeout, from}, 10_000)
        {:noreply, %{state | waiting: [from | state.waiting]}}
    end
  end

  def handle_call(:emergency_lock, _, state) do
    UART.write(state.nerves, "E")
    status = handle_locked(state.current, state.context)
    next = %{state |
      current: nil,
      timeouts: 0,
      status: status,
      initialized: false
    }
    {:reply, :ok, next}
  end

  def handle_call(:emergency_unlock, _, state) do
    UART.write(state.nerves, "F09")
    next = %{state | status: :idle, initialized: false}
    {:reply, :ok, next}
  end

  def handle_call(:available?, _, state), do: {:reply, state.initialized, state}

  def handle_call({:write, str, timeout}, from, %{status: :idle} = state)
  when is_binary(str) do
    handshake = generate_handshake()
    writeme =  "#{str} #{handshake}"

    # :ok = configure_uart(state.nerves, false)

    debug_log "writing: #{writeme}"
    :ok = UART.write(state.nerves, writeme)

    echo_ok = recieve_echo(state.nerves, writeme, "")

    # :ok = configure_uart(state.nerves, true)
    case echo_ok do
      :ok ->
        debug_log "timing this out in #{timeout} ms."
        timer = Process.send_after(self(), :timeout, timeout)
        current = %{
          status:   nil,
          reply:    nil,
          from:     from,
          q:        handshake,
          timer:    timer,
          callback: nil
        }
        {:noreply, %{state | current: current}}
      {:error, reason} ->
        {:reply, {:error, reason}, %{state | current: nil}}
    end

  end

  def handle_call({:write, _str, _timeout}, _from, %{status: status} = state) do
    debug_log "Serial Handler status: #{status}"
    {:reply, {:error, :bad_status}, state}
  end

  def handle_cast({:update_fw, file, pid}, state) do
    UART.close(state.nerves)
    Process.sleep(1000)
    if String.contains?(state.tty, "tnt") do
      Logger.warn "Not a real arduino!"
      send(pid, :done)
      {:noreply, state}
    else
      flash_firmware(state.context, state.tty, file, pid)
      {:stop, :update, state}
    end
  end

  def handle_info(:timeout, state) do
    current = state.current
    if current do
      debug_log "Timing out current: #{inspect current}"
      GenServer.reply(current.from, {:error, :timeout})
      check_timeouts(state)
    else
      debug_log "Got stray timeout."
      {:noreply, %{state | current: nil}}
    end
  end

  def handle_info({:waiting_timeout, from}, state) do
    if from in state.waiting do
      debug_log("Arduino is taking too long. Timing out waiting process: #{inspect from}")
      GenServer.reply(from, {:error, :timeout})
      {:noreply, %{state | waiting: List.delete(state.waiting, from)}}
    else
      {:noreply, state}
    end
  end

  def handle_info({:nerves_uart, tty, {:error, error}}, state) do
    Logger.error "#{tty} handler exiting!: #{error}"
    {:stop, error, state}
  end

  def handle_info({:nerves_uart, _tty, {:partial, _}}, s), do: {:noreply, s}

  def handle_info({:nerves_uart, _, str}, %{initialized: false} = state) do
    if String.contains?(str, "R00") do
      Logger.info "Initializing Firmware!"
      fn ->
        Process.sleep(2000)
        GenServer.cast(state.context.hardware, {:serial_ready, state.context})
      end.()
      {:noreply, %{state | initialized: true, status: :idle}}
    else
      debug_log "Serial not initialized yet: #{str}"
      {:noreply, state}
    end
  end

  def handle_info({:nerves_uart, _, str}, state) when is_binary(str) do
    debug_log "Reading: #{str}"
    case str |> Parser.parse_code |> do_handle(state.current, state.context) do
      :locked -> {:noreply, %{state | current: nil, status: :locked}}
      {:callback, str, current} ->
        debug_log "setting callback: #{str}"
        :ok = UART.write(state.nerves, str)
        {:noreply, %{state | current: current}}
      current ->
        if state.current.timer do
          true = Process.cancel_timer(state.current.timer)
        end
        next = %{state |
          current: current, status: current[:status] || :idle, timeouts: 0
        }
        if next.status == :idle do
          waiting = do_resolve_waiting(state.waiting)
          {:noreply, %{next | waiting: waiting}}
        else
          {:noreply, next}
        end
    end
  end

  def terminate(_, :no_state), do: :ok
  def terminate(_reason, state) do
    UART.close(state.nerves)
    UART.stop(state.nerves)
  end

  # This function should be called after every write and makes a couple assumptions.
  defp recieve_echo(_nerves, writeme, acc) do
    debug_log "Waiting for echo: sent: #{writeme} have: #{acc}"
    # this could return {:error, reason}
    receive do
      {:nerves_uart, _, bin} when is_binary(bin) -> parse_echo(acc <> bin, writeme)
      {:nerves_uart, _, {:error, reason}} -> {:error, reason}
    end
  end

  defp parse_echo(echo, writeme) do
    debug_log "Parsing echo: #{echo}"
    case echo do
      # R08 means valid command + whatever you wrote.
      "R08 " <> echo ->
        if echo |> String.trim() |> String.contains?(writeme), do: :ok, else: {:error, :bad_echo}
      # R09  means invalid command.
      << "R09", _ :: binary >> -> {:error, :invalid}
      # R87 is E stop
      << "R87", _ :: binary >> -> {:error, :emergency_lock}
      other                    -> {:error, "unhandled echo: #{other}"}
    end
  end

  defp do_resolve_waiting(list) do
    from = List.last(list)
    if from do
      GenServer.reply(from, :ok)
    end
    List.delete(list, from)
  end

  @spec do_handle({binary, any}, current | nil, Context.t)
    :: current | nil | :locked
  defp do_handle({_qcode, parsed}, current, %Context{} = ctx)
  when is_map(current) do
    if current.timer do
      true = Process.cancel_timer(current.timer)
    end
    results = handle_gcode(parsed, ctx)
    debug_log "Handling results: #{inspect results}"
    case results do
      {:status, :done}   -> handle_done(current)
      {:status, :busy}   -> handle_busy(current)
      {:status, :locked} -> handle_locked(current, ctx)
      {:status, status}  -> %{current | status: status}
      {:callback, str}   -> %{current | callback: str}
      {:reply,  reply}   -> %{current | reply: reply}
      thing              -> handle_other(thing, current)
    end
  end

  defp do_handle({_qcode, parsed}, nil, %Context{} = ctx) do
    handle_gcode(parsed, ctx)
    nil
  end

  @spec handle_locked(current, Context.t) :: :locked
  defp handle_locked(current, ctx) do
    if current do
      true = Process.cancel_timer(current.timer)
    end
    # Side effects.
    Farmbot.BotState.lock_bot(ctx)
    :locked
  end

  @spec handle_busy(current) :: current
  defp handle_busy(current) do
    debug_log "refreshing timer."
    true = Process.cancel_timer(current.timer)
    timer = Process.send_after(self(), :timeout, @default_timeout_ms)
    %{current | status: :busy, timer: timer}
  end

  defp handle_other(thing, current) do
    unless is_nil(thing) do
      debug_log "Unexpected thing: #{inspect thing}"
    end
    current
  end

  defp handle_done(current) do
    debug_log "replying to #{inspect current.from} with: #{inspect current.reply}"
    if current.callback do
      Process.cancel_timer(current.timer)
      handshake = generate_handshake()
      writeme   =  "#{current.callback} #{handshake}"
      timer     = Process.send_after(self(), :timeout, @default_timeout_ms)
      current   = %{
        status:   nil,
        reply:    nil,
        from:     current.from,
        q:        handshake,
        timer:    timer,
        callback: nil
      }
      {:callback, writeme, current}
    else
      GenServer.reply(current.from, current.reply || "R02")
      nil
    end
  end

  @spec generate_handshake :: binary
  defp generate_handshake, do: "Q#{:rand.uniform(99)}"

  @spec handle_gcode(any, Context.t) :: {:status, any} | {:reply, any} | nil

  defp handle_gcode(:report_emergency_lock, _),    do: {:status, :locked}
  defp handle_gcode(:idle, %Context{} = _ctx),     do: {:status, :idle}
  defp handle_gcode(:busy, %Context{} = _ctx),     do: {:status, :busy}
  defp handle_gcode(:done, %Context{} = _ctx),     do: {:status, :done}
  defp handle_gcode(:received, %Context{} = _ctx), do: {:status, :received}
  defp handle_gcode(:error, %Context{} = _ctx),    do: {:reply, :error}
  defp handle_gcode(:report_params_complete, _),   do: {:reply, :report_params_complete}
  defp handle_gcode(:noop, %Context{} = _ctx),     do: nil

  defp handle_gcode({:debug_message, message}, %Context{} = _ctx) do
    debug_log "R99 #{message}"
    nil
  end

  defp handle_gcode({:report_pin_value, pin, value} = reply, %Context{} = ctx)
  when is_integer(pin) and is_integer(value) do
    BotState.set_pin_value(ctx, pin, value)
    {:reply, reply}
  end

  defp handle_gcode({:report_current_position, x_steps, y_steps, z_steps} = reply, %Context{} = ctx) do
    thing_x = spm(:x, ctx)
    thing_y = spm(:y, ctx)
    thing_z = spm(:z, ctx)
    r = BotState.set_pos(ctx,
      Maths.steps_to_mm(x_steps, thing_x),
      Maths.steps_to_mm(y_steps, thing_y),
      Maths.steps_to_mm(z_steps, thing_z))
    debug_log "Position report reply: #{inspect r}"
    {:reply, reply}
  end

  defp handle_gcode({:report_parameter_value, param, value} = reply, %Context{} = ctx)
  when is_atom(param) and is_integer(value) do
    unless value == -1 do
      BotState.set_param(ctx, param, value)
    end
    {:reply, reply}
  end

  defp handle_gcode({:report_axis_calibration, param, value}, ctx) do
    p = Parser.parse_param(param)
    BotState.set_param(ctx, param, value)
    {:callback, "F22 P#{p} V#{value}"}
  end

  defp handle_gcode({:report_calibration, axis, status} = reply, _ctx) do
    Logger.info ">> Calibration message: #{axis}: #{status}"
    {:reply, reply}
  end

  defp handle_gcode(
    {:report_end_stops, x1, x2, y1, y2, z1, z2} = reply, %Context{} = ctx)
  do
    BotState.set_end_stops(ctx, {x1, x2, y1, y2, z1, z2})
    {:reply, reply}
  end

  defp handle_gcode({:report_encoder_position_scaled, x, y, z} = reply, %Context{} = ctx) do
    BotState.set_scaled_encoders(ctx, x, y, z)
    {:reply, reply}
  end

  defp handle_gcode({:report_encoder_position_raw, x, y, z} = reply, %Context{} = ctx) do
    BotState.set_raw_encoders(ctx, x, y, z)
    {:reply, reply}
  end

  defp handle_gcode({:report_software_version, version} = reply, %Context{} = ctx) do
    BotState.set_fw_version(ctx, version)
    {:reply, reply}
  end

  defp handle_gcode({:unhandled_gcode, code}, %Context{} = _ctx) do
    Logger.warn ">> got an misc gcode #{code}"
    {:reply, code}
  end

  defp handle_gcode(parsed, %Context{} = _ctx) do
    Logger.warn "Unhandled message: #{inspect parsed}"
    {:reply, parsed}
  end

  defp check_timeouts(state) do
    if state.timeouts > @max_timeouts do
      debug_log "reached max timeouts!"
      :ok = UART.close(state.nerves)
      Process.sleep(5000)
      {:stop, :max_timeouts, state}
    else
      {:noreply, %{state | current: nil, timeouts: state.timeouts + 1}}
    end
  end

  def flash_firmware(%Context{} = _ctx, tty, hex_file, pid) do
    Logger.info ">> Starting arduino firmware flash", type: :busy
    args =
      ["-patmega2560",
       "-cwiring",
       "-P/dev/#{tty}",
       "-b115200",
       "-D", "-q", "-V",
       "-Uflash:w:#{hex_file}:i"]

     avrdude = System.find_executable("avrdude")
     port_args = [
       :stream,
       :binary,
       :exit_status,
       :hide,
       :use_stdio,
       :stderr_to_stdout,
       args: args
     ]
     port = Port.open({:spawn_executable, avrdude}, port_args)
     timer = Process.send_after(self(), :flash_timeout, 20_000)
     r = handle_port(port, timer)
     send(pid, r)
  end

  defp handle_port(port, timer) do
    receive do
      {^port, {:data, contents}} ->
        debug_log(contents)
        handle_port(port, timer)
      {^port, {:exit_status, 0}} ->
        Logger.info(">> Flashed new arduino firmware", type: :success)
        Process.cancel_timer(timer)
        :done
      {^port, {:exit_status, error_code}} ->
        Logger.error ">> Could not flash firmware (#{error_code})"
        Process.cancel_timer(timer)
        {:error, error_code}
      :flash_timeout ->
        Logger.error ">> Timed out flashing firmware!"
        # info = Port.info(port)
        # if info do
        #   send port, {self(), :close}
        #   "kill" |> System.cmd(["15", "#{info.os_pid}"])
        # end
        {:error, :flash_timeout}
      after 21_000 ->
        Logger.error ">> Timed out flashing firmware!"
        {:error, :flash_timeout}
    end
  end

  @spec spm(atom, Context.t) :: integer
  defp spm(xyz, %Context{} = ctx) do
    spm = "steps_per_mm_#{xyz}" |> String.to_atom
    Farmbot.BotState.get_config(ctx, spm)
  end
end
