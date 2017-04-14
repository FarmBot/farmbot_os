defmodule Farmbot.Serial.Handler do
  @moduledoc """
    Handles communication between farmbot and uart devices
  """

  use GenServer
  require Logger
  alias Nerves.UART
  alias Farmbot.Serial.Gcode.Parser
  alias Farmbot.BotState
  alias Farmbot.Lib.Maths

  @typedoc """
    Handler pid or name
  """
  @type handler :: pid | atom

  @typedoc """
    Nerves.UART pid or name
  """
  @type nerves :: handler

  @type state :: {:hey, :fixme}

  @default_timeout_ms 10_000
  @max_timeouts 5

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
  def available?(handler \\ __MODULE__)

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
  def get_state(handler \\ __MODULE__), do: GenServer.call(handler, :get_state)

  @doc """
    Writes a string to the uart line
  """
  @spec write(binary, integer, handler) :: binary | {:error, atom}
  def write(string, timeout \\ @default_timeout_ms, handler \\ __MODULE__)
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
  @spec e_stop(handler) :: :ok | no_return
  def e_stop(handler \\ __MODULE__) do
    GenServer.call(handler, :e_stop)
  end

  ## Private

  def init({nerves, tty}) when is_pid(nerves) and is_binary(tty) do
    Process.link(nerves)
    :ok = open_tty(nerves, tty)
    GenServer.cast(Farmbot.BotState.Hardware, :eff)
    {:ok, %{nerves: nerves, tty: tty, current: nil, timeouts: 0}}
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

  def handle_call(:get_state, _, state), do: {:reply, state, state}

  def handle_call(:available?, _, state), do: {:reply, true, state}

  def handle_call({:write, str, timeout}, from, state) do
    handshake = generate_handshake()
    writeme =  "#{str} #{handshake}"
    IO.puts "writing: #{writeme}"
    UART.write(state.nerves, writeme)
    timer = Process.send_after(self(), :timeout, timeout)
    current = %{status: nil, reply: nil, from: from, q: handshake, timer: timer}
    {:noreply, %{state | current: current}}
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
      IO.puts "Timing out current"
      GenServer.reply(current.from, :timeout)
    end
    check_timeouts(state)
  end

  def handle_info({:nerves_uart, tty, str}, state) when is_binary(str) do
    if tty == state.tty do
      IO.puts "Reading: #{str}"
      try do
        current = str |> Parser.parse_code |> do_handle(state.current)
        {:noreply, %{state | current: current}}
      rescue
        e ->
          Logger.warn "uh oh: #{inspect e}"
          {:noreply, state}
      end
    end
  end

  def handle_info({:nerves_uart, _tty, {:partial, _}}, s), do: {:noreply, s}

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
    case handle_gcode(parsed) do
      {:status, :done} ->
        GenServer.reply(current.from, current.reply)
        Process.cancel_timer(current.timer)
        nil
      {:status, status} -> %{current | status: status}
      {:reply, reply} -> %{current | reply: reply}
      _ -> current
    end
  end

  defp do_handle({_qcode, parsed}, nil) do
    handle_gcode(parsed)
    nil
  end

  @spec generate_handshake :: binary
  defp generate_handshake, do: "Q#{:rand.uniform(99)}"

  @spec handle_gcode(any) :: {:status, any} | {:reply, any} | nil
  defp handle_gcode(:idle), do: {:status, :idle}

  defp handle_gcode(:busy) do
    Logger.info ">>'s arduino is busy.", type: :busy
    {:status, :busy}
  end

  defp handle_gcode(:done), do: {:status, :done}

  defp handle_gcode(:received), do: {:status, :received}

  defp handle_gcode({:debug_message, message}) do
    Logger.info ">>'s arduino says: #{message}"
    nil
  end

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

  defp handle_gcode({:reporting_end_stops, x1,x2,y1,y2,z1,z2} = reply) do
    BotState.set_end_stops({x1,x2,y1,y2,z1,z2})
    {:reply, reply}
  end

  defp handle_gcode({:report_software_version, version} = reply) do
    BotState.set_fw_version(version)
    {:reply, reply}
  end

  defp handle_gcode(:error), do: {:reply, :error}

  defp handle_gcode(:dont_handle_me), do: nil

  defp handle_gcode({:unhandled_gcode, code}) do
    Logger.warn ">> got an misc gcode #{code}"
    {:reply, code}
  end

  defp handle_gcode(parsed) do
    Logger.warn "Unhandled message: #{inspect parsed}"
    {:reply, parsed}
  end

  defp check_timeouts(state) do
    if state.timeouts > @max_timeouts do
      IO.puts "reached max timeouts!"
      :ok = UART.close(state.nerves)
      Process.sleep(5000)
      {:stop, :max_timeouts, state}
    else
      {:noreply, %{state | current: nil, timeouts: state.timeouts + 1}}
    end
  end

  def flash_firmware(tty, hex_file, pid) do
    params =
      ["-v",
       "-patmega2560",
       "-cwiring",
       "-P/dev/#{tty}",
       "-b115200",
       "-D",
       "-Uflash:w:#{hex_file}:i"]

    "avrdude" |> System.cmd(params) |> log(pid)
  end

  defp log({_, 0}, pid) do
    Logger.info "FLASHED FIRMWARE!"
    send pid, :done
  end

  defp log(stuff, pid) do
    Logger.error "FAILED TO FLASH FIRMWARE!"
    send pid, {:error, stuff}
  end

  @spec spm(atom) :: integer
  defp spm(xyz) do
    "steps_per_mm_#{xyz}"
    |> String.to_atom
    |> Farmbot.BotState.get_config()
  end
end
