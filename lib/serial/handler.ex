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

  @default_tracker :default_tracker
  @race_fix 5000

  @typedoc """
    Handler pid or name
  """
  @type handler :: pid | atom

  @typedoc """
    Nerves.UART pid or name
  """
  @type nerves :: handler

  @type state :: %{
    nerves: nerves,
    tty: binary,
    queue: :queue.queue,
    handshakes: %{required(binary) => %{from: {pid, reference}, reply: any}}
  }

  @doc """
    Starts a UART GenServer
  """
  def start_link(nerves, tty) do
    GenServer.start_link(__MODULE__, {nerves, tty})
  end

  @doc """
    Gets the default UART handler
  """
  @spec get_default :: nil | pid
  def get_default do
    Agent.get(@default_tracker, fn(thing) -> thing end)
  end

  @doc """
    Checks if we have a handler available
  """
  @spec available?(handler) :: boolean
  def available?(handler \\ __MODULE__) do
    uh = Process.whereis(handler)
    if uh, do: true, else: false
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
      GenServer.call(handler, {:write, str}, timeout)
    else
      {:error, :unavailable}
    end
  end

  ## Private

  @spec init({nerves, binary}) :: {:ok, state} | :ignore
  def init({nerves, tty}) do
    Logger.debug "Starting serial handler: #{tty}"
    :ok = UART.open(nerves, tty)

    # configure framing
    UART.configure(nerves,
      framing: {UART.Framing.Line, separator: "\r\n"},
      active: true,
      rx_framing_timeout: 500)

    # Black magic to fix races
    Process.sleep(@race_fix)

    UART.flush(nerves)

    # generate a handshake
    handshake = generate_handshake()
    Logger.debug "doing handshaking: #{handshake}"

    if do_handshake(nerves, tty, handshake) do
      update_default(self())
      # nerves |> UART.read(5000) |> validate(tty, handshake, {sup, nerves})
      state = %{tty: tty, nerves: nerves, queue: :queue.new(), handshakes: %{}}
      {:ok, state}
    else
      :ignore
    end
  end

  @spec generate_handshake :: binary
  defp generate_handshake do
    random_int = :rand.uniform(99)
    "Q#{random_int}"
  end

  @spec do_handshake(nerves, binary, binary, integer) :: boolean
  defp do_handshake(nerves, tty, handshake, retries \\ 5)

  defp do_handshake(_, _, _, 0) do
    Logger.debug "Could not handshake: to many retries."
    false
  end

  defp do_handshake(nerves, tty, handshake, retries) do
    UART.write(nerves, "F83 #{handshake}")
    receive do
      {:nreves_uart, ^tty, {:partial, _}} ->
        UART.flush(nerves)
        do_handshake(nerves, tty, handshake)
      {:nerves_uart, ^tty, "R01" <> _} -> do_handshake(nerves, tty, handshake)
      {:nerves_uart, ^tty, str} ->
        # Logger.debug "trying: #{str}"
        if String.contains?(str, handshake) do
          Logger.debug "Successfully completed handshake!"
          "R83 " <> version = String.trim(str, " " <> handshake)
          Farmbot.BotState.set_fw_version(version)
          UART.flush(nerves)
          true
        else
          do_handshake(nerves, tty, handshake)
        end
      uh ->
        Logger.warn "Could not handshake: #{inspect uh}"
        false
      after
        2_000 ->
          Logger.warn "Could not handshake: timeout, retrying."
          do_handshake(nerves, tty, handshake, retries - 1)
    end
  end

  @spec update_default(pid) :: :ok | no_return
  defp update_default(pid) do
    Agent.update(@default_tracker, fn(_) ->
      pid
    end)
    old_pid = Process.whereis(__MODULE__)
    if old_pid do
      Logger.debug "Deregistering #{inspect old_pid} from default Serial Handler"
      Process.unregister(__MODULE__)
    end

    Process.register(pid, __MODULE__)
  end

  def handle_call({:write, str}, from, state) do
    # generate a handshake
    handshake = generate_handshake()
    handshakes = Map.put(state.handshakes, handshake, %{reply: nil, from: from})
    # if the queue is empty, write this string now.
    if :queue.is_empty(state.queue) do
      UART.write(state.nerves, str <> " Q#{handshake}")
      {:noreply, %{state | handshakes: handshakes}}
    else
      q = :queue.in({str, handshake}, state.queue)
      {:noreply, %{state | queue: q, handshakes: handshakes}}
    end
  end

  def handle_info({:nerves_uart, tty, gcode}, state) do
    unless tty != state.tty do
      parsed = Parser.parse_code(gcode)
      handle_gcode(parsed, state)
    end
  end

  defp handle_gcode({:debug_message, message}, state) do
    Logger.info ">>'s arduino says: #{message}"
    {:noreply, state}
  end

  defp handle_gcode({:idle, _}, state) do
    {:noreply, state}
  end

  defp handle_gcode({:busy, _}, state) do
    Logger.info ">>'s arduino is busy.", type: :busy
    {:noreply, state}
  end

  defp handle_gcode({:done, hs}, state) do
    # reply to blerp if it exists
    new_handshakes = maybe_reply(state, hs)

    {thing, q} = :queue.out(state.queue)

    unless thing == :empty do
      {str, new_hs} = thing
      UART.write(state.nerves, str <> " Q#{new_hs}")
    end

    {:noreply, %{state | handshakes: new_handshakes, queue: q}}
  end

  defp handle_gcode({:received, _}, state) do
    {:noreply, state}
  end

  defp handle_gcode({:report_pin_value, pin, value, hs} = reply, state)
  when is_integer(pin) and is_integer(value) do
    new_handshakes = set_reply(state, hs, reply)
    BotState.set_pin_value(pin, value)
    {:noreply, %{state | handshakes: new_handshakes}}
  end

  defp handle_gcode({:report_current_position, x_steps,y_steps,z_steps, hs} = reply, state) do
    BotState.set_pos(
      Maths.steps_to_mm(x_steps, spm(:x)),
      Maths.steps_to_mm(y_steps, spm(:y)),
      Maths.steps_to_mm(z_steps, spm(:z)))
    new_handshakes = set_reply(state, hs, reply)
    {:noreply, %{state | handshakes: new_handshakes}}
  end

  defp handle_gcode({:report_parameter_value, param, value, hs} = reply, state)
  when is_atom(param) and is_integer(value) do
    BotState.set_param(param, value)
    new_handshakes = set_reply(state, hs, reply)
    {:noreply, %{state | handshakes: new_handshakes}}
  end

  defp handle_gcode({:reporting_end_stops, x1,x2,y1,y2,z1,z2, hs} = reply, state) do
    BotState.set_end_stops({x1,x2,y1,y2,z1,z2})
    new_handshakes = set_reply(state, hs, reply)
    {:noreply, %{state | handshakes: new_handshakes}}
  end

  defp handle_gcode({:report_software_version, version, hs} = reply, state) do
    BotState.set_fw_version(version)
    new_handshakes = set_reply(state, hs, reply)
    {:noreply, %{state | handshakes: new_handshakes}}
  end

  defp handle_gcode({:unhandled_gcode, code}, state) do
    Logger.warn ">> got an unhandled gcode! #{code}"
    {:noreply, state}
  end

  defp handle_gcode(:dont_handle_me, state), do: {:noreply, state}

  defp handle_gcode(parsed, state) do
    Logger.warn "Unhandled GCODE: #{inspect parsed}"
    {:noreply, state}
  end

  @spec spm(atom) :: integer
  defp spm(xyz) do
    "steps_per_mm_#{xyz}"
    |> String.to_atom
    |> Farmbot.BotState.get_config()
  end

  @spec maybe_reply(state, binary) :: map
  defp maybe_reply(state, hs) do
    IO.inspect state
    blerp = Map.get(state.handshakes, hs)
    if blerp do
      GenServer.reply(blerp.from, blerp.reply)
      Map.delete(state.handshakes, hs)
    else
      state.handshakes
    end
  end

  @spec set_reply(state, binary, any) :: map
  defp set_reply(state, hs, reply) do
    IO.inspect state
    blerp = Map.get(state.handshakes, hs)
    if blerp do
      %{state.handshakes | hs => reply}
    else
      state.handshakes
    end
  end
end
