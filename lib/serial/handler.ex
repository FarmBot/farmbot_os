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

  @race_fix 5000

  @typedoc """
    Handler pid or name
  """
  @type handler :: pid | atom

  @typedoc """
    Nerves.UART pid or name
  """
  @type nerves :: handler

  @typedoc """
    The current command in the buffer being worked on.
  """
  @type current :: %{
    reply: nil | term,
    handshake: binary,
    timeout: reference | nil,
    from: {pid, reference}
  }

  @typedoc """
    State of the GenServer
  """
  @type state :: %{
    nerves: nerves,
    tty: binary,
    queue: :queue.queue,
    current: nil | :no_firm | current
  }

  @doc """
    Starts a UART GenServer
  """
  def start_link(nerves, tty) do
    GenServer.start_link(__MODULE__, {nerves, tty})
  end

  @doc """
    Checks if we have a handler available
  """
  @spec available?(handler) :: boolean
  def available?(handler \\ __MODULE__)

  def available?(handler) when is_pid(handler) do
    GenServer.call(handler, :available?)
  end

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
  def write(string, timeout \\ 7000, handler \\ __MODULE__)
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

  @spec open_tty(nerves, binary) :: :ok
  defp open_tty(nerves, tty) do
    # Open the tty
    :ok = UART.open(nerves, tty)

    # configure framing
    UART.configure(nerves,
      framing: {UART.Framing.Line, separator: "\r\n"},
      active: true,
      rx_framing_timeout: 500)

    # Black magic to fix races
    Process.sleep(@race_fix)

    # Flush the buffers so we start fresh
    UART.flush(nerves)

    :ok
  end

  @spec init({nerves, binary}) :: {:ok, state} | :ignore
  def init({nerves, tty}) do
    Process.link(nerves)
    Logger.info "Starting serial handler: #{tty}"

    :ok = open_tty(nerves, tty)
    update_default(self())

    # generate a handshake
    handshake = generate_handshake()
    Logger.info "doing handshaking: #{handshake}"

    if do_handshake(nerves, tty, handshake) do
      UART.write(nerves, "F83 #{handshake}") # ???
      do_hax()
      state = %{tty: tty, nerves: nerves, queue: :queue.new(), current: nil}
      {:ok, state}
    else
      Logger.warn "Handshake failed!"
      state = %{
        tty: tty, nerves: nerves, queue: :queue.new(), current: :no_firm
      }
      {:ok, state}
    end
  end

  # Shhhhh
  @spec do_hax :: no_return
  defp do_hax, do: GenServer.cast(Farmbot.BotState.Hardware, :eff)

  @spec generate_handshake :: binary
  defp generate_handshake do
    random_int = :rand.uniform(99)
    "Q#{random_int}"
  end

  @spec do_handshake(nerves, binary, binary, integer) :: boolean
  defp do_handshake(nerves, tty, handshake, retries \\ 5)

  defp do_handshake(_, _, _, 0) do
    Logger.info "Could not handshake: to many retries."
    false
  end

  defp do_handshake(nerves, tty, handshake, retries) do
    # Write a command to UART
    UART.write(nerves, "F83 #{handshake}")

    # Wait for it to respong
    receive do
      # if it sends a partial, we are probably out of sync
      # flush the buffer and try again.
      {:nreves_uart, ^tty, {:partial, _}} ->
        UART.flush(nerves)
        do_handshake(nerves, tty, handshake)

      # Recieved happens before our actual response, just go to the next one
      # if it exists
      {:nerves_uart, ^tty, "R01" <> _} -> do_handshake(nerves, tty, handshake)
      {:nerves_uart, ^tty, "Command:" <> _} -> do_handshake(nerves, tty, handshake)

      # This COULD be our handshake. Check it.
      {:nerves_uart, ^tty, str} ->
        # if it contains our handshake, check if its the right command.
        # flush the buffer and return
        if String.contains?(str, handshake) do
          Logger.info "Successfully completed handshake!"
          "R83 " <> version = String.trim(str, " " <> handshake)
          Farmbot.BotState.set_fw_version(version)
          UART.flush(nerves)
          true
        else
          # If not, Move on to the next thing in the buffer.
          do_handshake(nerves, tty, handshake)
        end
      uh ->
        # if we recieve some other stuff, we have a leak or something.
        # I think this can be deleted.
        Logger.warn "Could not handshake: #{inspect uh}"
        false
      after
        # After 2 seconds try again.
        2_000 ->
          Logger.warn "Could not handshake: timeout, retrying."
          do_handshake(nerves, tty, handshake, retries - 1)
    end
  end

  @spec update_default(pid) :: :ok | no_return
  defp update_default(pid) do
    deregister()
    # Either way, register this pid as the new one.
    Process.register(pid, __MODULE__)
  end

  @spec deregister :: no_return
  defp deregister do
    # lookup the old default pid
    old_pid = Process.whereis(__MODULE__)

    # if one existst, unregister it.
    if old_pid do
      Logger.info "Deregistering #{inspect old_pid} from default Serial Handler"
      Process.unregister(__MODULE__)
    end
  end

  def handle_call(:get_state, _, state), do: {:reply, state, state}

  def handle_call(:available?, _from, state) do
    case state.current do
      :no_firm -> {:reply, false, state}
      _ -> {:reply, true, state}
    end
  end

  # A new line to write.
  def handle_call({:write, str, timeout}, from, state) do
    # generate a handshake
    handshake = generate_handshake()
    # if the queue is empty, write this string now.
    if :queue.is_empty(state.queue) do
      ref = Process.send_after(self(), {:timeout, from, handshake}, timeout)
      current = %{reply: nil, handshake: handshake, timeout: ref, from: from}
      UART.write(state.nerves, str <> " #{handshake}")
      {:noreply, %{state | current: current}}
    else
      q = :queue.in({str, handshake, from, timeout}, state.queue)
      {:noreply, %{state | queue: q}}
    end
  end

  def handle_cast({:update_fw, hex_file, pid}, state) do
    if String.contains?(state.tty, "tnt") do
      send(pid, :done)
      {:noreply, state}
    else
      UART.close(state.nerves)
      Process.sleep(100)
      flash_firmware(state.tty, hex_file, pid)
      Process.sleep(5000)
      {:ok, new_state} = init({state.nerves, state.tty})
      {:noreply, new_state}
    end
  end

  def handle_info({:timeout, from, handshake}, state) do
    current = state.current
    if current do
      new_current = maybe_timeout({from, handshake}, current)
      {:noreply, %{state | current: new_current}}
    else
      {:noreply, state}
    end
  end

  def handle_info({:nerves_uart, _tty, {:partial, thing}}, state) do
    Logger.warn ">> got partial gcode: #{thing}"
    {:noreply, state}
  end

  def handle_info({:nerves_uart, _tty, {:error, :eio}}, state) do
    Logger.error "ARDUINO DISCONNECTED!"
    {:noreply, %{state | queue: :queue.new(), current: nil}}
  end

  # This is when we get a code in from nerves_uart
  @lint false # this is just a mess sorry
  def handle_info({:nerves_uart, tty, gcode}, state) do
    unless tty != state.tty do
      parsed = Parser.parse_code(gcode)
      case parsed do
        # if the code has a handshake and its not done
        # we just want to handle the code. Nothing special.

        # derp
        {:debug_message, _message} ->
          handle_gcode(parsed, state)

        {_hs, :done} ->
          current = if state.current do
            # cancel the timer
            Process.cancel_timer(state.current.timeout)
            # reply to the client
            GenServer.reply(state.current.from, state.current.reply)
            nil
          else
            state.current
          end
          handle_gcode(:done, %{state | current: current})

        # If its not done,
        {hs, code} ->
          current = if (state.current || false) && (state.current.handshake == hs) do
            %{state.current | reply: code}
          else
            state.current
          end
          handle_gcode(code, %{state | current: current})

        # anything else just handle the code.
        _ -> handle_gcode(parsed, state)
      end
    end
  end

  defp handle_gcode(:dont_handle_me, state), do: {:noreply, state}

  defp handle_gcode(:idle, state) do
    {:noreply, state}
  end

  defp handle_gcode(:busy, state) do
    Logger.info ">>'s arduino is busy.", type: :busy
    {:noreply, state}
  end

  defp handle_gcode(:done, state) do
    Process.sleep(100)
    # when we get done we need to check the queue for moar commands.
    # if there is more create a new current map, start a new timer etc.

    # if there is nothing in the queue, nothing to do here.
    if :queue.is_empty(state.queue) do
      {:noreply, state}
    # if there is something in the queue
    else
      {{str, handshake, from, millis}, q} = :queue.out(state.queue)
      ref = Process.send_after(self(), {:timeout, from, handshake}, millis)
      current = %{reply: nil, handshake: handshake, timeout: ref, from: from}
      UART.write(state.nerves, str <> " Q#{handshake}")
      {:noreply, %{state | current: current, queue: q}}
    end
  end

  defp handle_gcode(:received, state) do
    {:noreply, state}
  end

  defp handle_gcode({:debug_message, _message}, state) do
    # Logger.info ">>'s arduino says: #{message}"
    {:noreply, state}
  end

  defp handle_gcode({:report_pin_value, pin, value}, state)
  when is_integer(pin) and is_integer(value) do
    BotState.set_pin_value(pin, value)
    {:noreply, state}
  end

  defp handle_gcode({:report_current_position, x_steps,y_steps,z_steps}, state) do
    BotState.set_pos(
      Maths.steps_to_mm(x_steps, spm(:x)),
      Maths.steps_to_mm(y_steps, spm(:y)),
      Maths.steps_to_mm(z_steps, spm(:z)))
    {:noreply, state}
  end

  defp handle_gcode({:report_parameter_value, param, value}, state)
  when is_atom(param) and is_integer(value) do
    unless value == -1 do
      BotState.set_param(param, value)
    end
    {:noreply, state}
  end

  defp handle_gcode({:reporting_end_stops, x1,x2,y1,y2,z1,z2}, state) do
    BotState.set_end_stops({x1,x2,y1,y2,z1,z2})
    {:noreply, state}
  end

  defp handle_gcode({:report_software_version, version}, state) do
    BotState.set_fw_version(version)
    {:noreply, state}
  end

  defp handle_gcode({:unhandled_gcode, code}, state) do
    Logger.warn ">> got an misc gcode #{code}"
    {:noreply, state}
  end

  defp handle_gcode({:error, :ebadf}, state) do
    {:ok, new_state} = init({state.nerves, state.tty})
    {:noreply, new_state}
  end

  defp handle_gcode(parsed, state) do
    Logger.warn "Unhandled message: #{inspect parsed}"
    {:noreply, state}
  end

  def terminate(_, _) do
    Process.unregister(__MODULE__)
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
    # handler = Process.whereis(__MODULE__)
    # if handler, do: spawn fn() -> GenServer.stop(handler, :normal) end
    # Farmbot.Serial.Supervisor.open_ttys(Farmbot.Serial.Supervisor, [tty])
  end

  defp log({_, 0}, pid) do
    Logger.info "FLASHED FIRMWARE!"
    send pid, :done
  end

  defp log(_, pid) do
    Logger.error "FAILED TO FLASH FIRMWARE!"
    send pid, :error
  end

  @spec spm(atom) :: integer
  defp spm(xyz) do
    "steps_per_mm_#{xyz}"
    |> String.to_atom
    |> Farmbot.BotState.get_config()
  end

  @spec maybe_timeout({{pid, reference}, binary}, current) :: current
  defp maybe_timeout({from, handshake}, current) do
    # if we actually are working on the thing that this timeout was created
    # for, reply timeout to it.
    if (current.from == from) and (current.handshake == handshake) do
      GenServer.reply(from, {:error, :timeout})
      nil
    else
      # this was probably already finished or somthing. /shrug
      current
    end
  end
end
