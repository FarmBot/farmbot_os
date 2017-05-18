defmodule Farmbot.Serial.Handler do
  @moduledoc """
    Handles communication between farmbot and uart devices
  """

  alias Farmbot.BotState
  alias Farmbot.CeleryScript.Ast.Context
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

  @default_timeout_ms 10_000
  @max_timeouts 5

  def find_tty do
    case Application.get_env(:farmbot, :tty) do
      {:system, env} ->
        System.get_env(env)
      tty when is_binary(tty) -> tty
      nil ->
        UART.enumerate() |> Map.keys
    end
  end

  @doc """
    Starts a UART GenServer
  """
  def start_link(nerves, tty, opts) when is_pid(nerves) and is_binary(tty) do
    GenServer.start_link(__MODULE__, {nerves, tty}, opts)
  end

  @doc """
    Starts a UART GenServer
  """
  def start_link(tty, opts) when is_binary(tty) do
    GenServer.start_link(__MODULE__, tty, opts)
  end

  @doc """
    Checks if we have a handler available
  """
  @spec available?(handler) :: boolean
  def available?(handler)

  # If handler is a pid
  def available?(handler) when is_pid(handler) do
    GenServer.call(handler, :available?)
  end

  # if its a name, look it up
  def available?(handler) do
    uh = Process.whereis(handler)
    if uh do
      available?(uh)
    else
      false
    end
  end

  @doc """
    Gets the state of a handler
  """
  @spec get_state(handler) :: state
  def get_state(handler), do: GenServer.call(handler, :get_state)

  @doc """
    Writes a string to the uart line
  """
  @spec write(binary, integer, handler) :: binary | {:error, atom}
  def write(string, timeout \\ @default_timeout_ms, handler)
  def write(str, timeout, handler) do
    if available?(handler) do
      GenServer.call(handler, {:write, str, timeout}, :infinity)
    else
      {:error, :unavailable}
    end
  end

  @doc """
    Send the E stop command to the arduino.
  """
  @spec emergency_lock(handler) :: :ok | no_return
  def emergency_lock(handler) do
    GenServer.call(handler, :emergency_lock)
  end

  @doc """
    Tell the arduino its fine now.
  """
  @spec emergency_unlock(handler) :: :ok | no_return
  def emergency_unlock(handler) do
    GenServer.call(handler, :emergency_unlock)
  end

  ## Private

  def init({nerves, tty}) when is_pid(nerves) and is_binary(tty) do
    Process.link(nerves)
    :ok = open_tty(nerves, tty)
    state = %{
      nerves: nerves,
      tty: tty,
      current: nil,
      timeouts: 0,
      status: :busy,
      initialized: false
    }
    {:ok, state}
  end

  def init(tty) when is_binary(tty) do
    {:ok, nerves} = UART.start_link()
    init({nerves, tty})
  end

  @spec open_tty(nerves, binary) :: :ok
  defp open_tty(nerves, tty) do
    # Open the tty
    :ok = UART.open(nerves, tty)

    :ok = UART.configure(nerves,
      framing: {UART.Framing.Line, separator: "\r\n"},
      active: true,
      rx_framing_timeout: 500)

    # Flush the buffers so we start fresh
    :ok = UART.flush(nerves)
    :ok
  end

  def handle_call(:emergency_lock, _, state) do
    UART.write(state.nerves, "E")
    current = state.current
    if current do
      Process.cancel_timer(current.timer)
    end
    next = %{state |
      current: nil,
      timeouts: 0,
      status: :locked,
      initialized: false
    }
    {:reply, :ok, next}
  end

  def handle_call(:emergency_unlock, _, state) do
    UART.write(state.nerves, "F09")
    next = %{state | status: :idle, initialized: false}
    {:reply, :ok, next}
  end

  def handle_call(:get_state, _, state), do: {:reply, state, state}

  def handle_call(:available?, _, state), do: {:reply, state.initialized, state}

  def handle_call({:write, str, timeout}, from, %{status: :idle} = state) do
    handshake = generate_handshake()
    writeme =  "#{str} #{handshake}"
    debug_log "writing: #{writeme}"
    UART.write(state.nerves, writeme)
    timer = Process.send_after(self(), :timeout, timeout)
    current = %{status: nil, reply: nil, from: from, q: handshake, timer: timer}
    {:noreply, %{state | current: current}}
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
      flash_firmware(state.tty, file, pid)
      {:stop, :update, state}
    end
  end

  def handle_info(:timeout, state) do
    current = state.current
    if current do
      debug_log "Timing out current: #{inspect current}"
      GenServer.reply(current.from, :timeout)
      check_timeouts(state)
    else
      debug_log "Got stray timeout."
      {:noreply, %{state | current: nil}}
    end
  end

  def handle_info({:nerves_uart, _tty, {:partial, _}}, s), do: {:noreply, s}

  def handle_info({:nerves_uart, _, str}, %{initialized: false} = state) do
    if String.contains?(str, "R00") do
      Logger.info "Initializing Firmware!"
      fn ->
        Process.sleep(2000)
        ready = {:serial_ready, Context.new()}
        GenServer.cast(Farmbot.BotState.Hardware, ready)
      end.()
      {:noreply, %{state | initialized: true, status: :idle}}
    else
      debug_log "Serial not initialized yet: #{str}"
      {:noreply, state}
    end
  end

  def handle_info({:nerves_uart, _, str}, state) when is_binary(str) do
    debug_log "Reading: #{str}"
    try do
      current = str |> Parser.parse_code |> do_handle(state.current)
      {:noreply, %{state | current: current, status: current[:status] || :idle}}
    rescue
      e ->
        Logger.warn "Encountered an error handling: #{str}: #{inspect e}", rollbar: false
        {:noreply, state}
    end
  end

  def handle_info({:nerves_uart, tty, {:error, error}}, state) do
    Logger.error "#{tty} handler exiting!: #{error}"
    {:stop, error, state}
  end

  def terminate(reason, state) do
    UART.close(state.nerves)
    GenServer.stop(state.nerves, reason)
  end

  @spec do_handle({binary, any}, map | nil) :: map | nil
  defp do_handle({_qcode, parsed}, current) when is_map(current) do
    results = handle_gcode(parsed)
    debug_log "Handling results: #{inspect results}"
    case results do
      {:status, :done} -> handle_done(current)
      {:status, :busy} -> handle_busy(current)
      {:status, status} -> %{current | status: status}
      {:reply, reply} -> %{current | reply: reply}
      thing -> handle_other(thing, current)
    end
  end

  defp do_handle({_qcode, parsed}, nil) do
    handle_gcode(parsed)
    nil
  end

  @spec handle_busy(current) :: current
  defp handle_busy(current) do
    debug_log "refreshing timer."
    Process.cancel_timer(current.timer)
    timer = Process.send_after(self(), :timeout, 5000)
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
    GenServer.reply(current.from, current.reply)
    Process.cancel_timer(current.timer)
    nil
  end

  @spec generate_handshake :: binary
  defp generate_handshake, do: "Q#{:rand.uniform(99)}"

  @spec handle_gcode(any) :: {:status, any} | {:reply, any} | nil
  defp handle_gcode(:idle), do: {:status, :idle}

  defp handle_gcode(:busy) do
    # Logger.info ">>'s arduino is busy.", type: :busy
    {:status, :busy}
  end

  defp handle_gcode(:done), do: {:status, :done}

  defp handle_gcode(:received), do: {:status, :received}

  defp handle_gcode({:debug_message, message}) do
    debug_log "R99 #{message}"
    nil
  end

  defp handle_gcode(:report_params_complete), do: {:reply, :report_params_complete}

  defp handle_gcode({:report_pin_value, pin, value} = reply)
  when is_integer(pin) and is_integer(value) do
    BotState.set_pin_value(pin, value)
    {:reply, reply}
  end

  defp handle_gcode({:report_current_position, x_steps, y_steps, z_steps} = reply) do
    BotState.set_pos(
      Maths.steps_to_mm(x_steps, spm(:x)),
      Maths.steps_to_mm(y_steps, spm(:y)),
      Maths.steps_to_mm(z_steps, spm(:z)))
    {:reply, reply}
  end

  defp handle_gcode({:report_parameter_value, param, value} = reply)
  when is_atom(param) and is_integer(value) do
    unless value == -1 do
      BotState.set_param(param, value)
    end
    {:reply, reply}
  end

  defp handle_gcode({:report_end_stops, x1,x2,y1,y2,z1,z2} = reply) do
    BotState.set_end_stops({x1,x2,y1,y2,z1,z2})
    {:reply, reply}
  end

  defp handle_gcode({:report_encoder_position_scaled, x, y, z}) do
    debug_log "scaled encoders: #{inspect {x, y, z}}"
    nil
  end

  defp handle_gcode({:report_encoder_position_raw, x, y, z}) do
    debug_log "raw encoders: #{inspect {x, y, z}}"
    nil
  end

  defp handle_gcode({:report_software_version, version} = reply) do
    BotState.set_fw_version(version)
    {:reply, reply}
  end

  defp handle_gcode(:error), do: {:reply, :error}

  defp handle_gcode(:dont_handle_me), do: nil

  defp handle_gcode({:unhandled_gcode, code}) do
    Logger.info ">> got an misc gcode #{code}", type: :warn
    {:reply, code}
  end

  defp handle_gcode(parsed) do
    Logger.warn "Unhandled message:" <>
      " #{inspect parsed}", rollbar: false
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

  def flash_firmware(tty, hex_file, pid) do
    Logger.info ">> Starting arduino firmware flash", type: :busy
    args =
      ["-patmega2560",
       "-cwiring",
       "-P/dev/#{tty}",
       "-b115200",
       "-D", "-q", "-q", "-V",
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

  @spec spm(atom) :: integer
  defp spm(xyz) do
    "steps_per_mm_#{xyz}"
    |> String.to_atom
    |> Farmbot.BotState.get_config()
  end
end
