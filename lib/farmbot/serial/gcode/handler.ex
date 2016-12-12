defmodule Farmbot.Serial.Gcode.Handler do
  @moduledoc """
    Handles parsed messages.
  """
  require Logger
  use GenServer
  alias Farmbot.BotState

  def start_link(nerves) do
    GenServer.start_link(__MODULE__, nerves, name: __MODULE__)
  end

  def init(nerves) do
    {:ok, %{nerves: nerves, current: nil, log: []}}
  end

  def handle_cast({:debug_message, str}, state) do
    Logger.debug ">> got a message from my arduino: #{str}"
    {:noreply, state}
  end

  def handle_cast({:idle, _}, state) do
    {:noreply, %{nerves: state.nerves, current: nil, log: []}}
  end

  def handle_cast({:busy, _}, state) do
    {_, pid} = state.current
    send(pid, :busy)
    Logger.debug ">>'s arduino is busy.", type: :busy
    {:noreply, state}
  end

  def handle_cast({:done, _}, %{nerves: nerves, current: {_current_str, pid},
    log: log})
  do
    send(pid, :done)
    case List.first(log) do
      {nextstr, new_pid} ->
        Farmbot.Serial.Handler.write(nextstr, new_pid)
        {:noreply, %{nerves: nerves, current: {nextstr, new_pid},
          log: log -- [{nextstr, new_pid}]}}
      nil ->
        {:noreply, %{nerves: nerves, current: nil, log: []}}
    end
  end

  def handle_cast({:done, _}, state) do
    {:noreply, %{nerves: state.nerves, current: nil, log: []}}
  end

  def handle_cast({:received, _}, state) do
    {:noreply, state}
  end

  def handle_cast({:report_pin_value, pin, value, _}, state)
  when is_integer(pin) and is_integer(value) do
    BotState.set_pin_value(pin, value)
    {:noreply, state}
  end

  def handle_cast({:report_current_position, x,y,z, _}, state) do
    BotState.set_pos(x,y,z)
    {:noreply, state}
  end

  def handle_cast({:report_parameter_value, param, value, _}, state)
  when is_atom(param) and is_integer(value) do
    BotState.set_param(param, value)
    {:noreply, state}
  end

  def handle_cast({:reporting_end_stops, x1,x2,y1,y2,z1,z2,_}, state) do
    BotState.set_end_stops({x1,x2,y1,y2,z1,z2})
    {:noreply, state}
  end

  # If we arent waiting on anything right now. (current is nil and log is empty)
  def handle_cast({:send, message, caller}, %{nerves: nerves, current: nil, log: []})
  when is_bitstring(message) do
    Farmbot.Serial.Handler.write(message, caller)
    {:noreply, %{nerves: nerves, current: {message, caller}, log: []}}
  end

  def handle_cast({:send, message, caller},
                  %{nerves: nerves, current: current, log: log}) do
    {:noreply,
     %{nerves: nerves, current: current, log: log ++ [{message, caller}]}}
  end

  def handle_cast(event, state) do
    Logger.debug ">> got an unhandled gcode! #{inspect event}"
    {:noreply, state}
  end

  def handle_call(:state, _from, state), do: {:reply, state, state}

  @doc """
    Sends a message and blocks until it completes, or times out.
    The default timeout is ten seconds.
  """
  @spec block_send(binary, integer) :: atom
  def block_send(str, timeout \\ 10_000) do
    GenServer.cast(Farmbot.Serial.Gcode.Handler,{:send, str, self()})
    __MODULE__.block(timeout)
  end

  @doc """
    Blocks current process until a serial command returns.
  """
  @spec block(integer) :: atom
  def block(timeout) do
    receive do
      :done -> :done
      :e_stop ->
        GenServer.cast(__MODULE__, {:done, nil})
        :e_stop
      :busy -> block(timeout)
      error -> error
    after
      timeout -> :timeout
    end
  end

  # I think i put these here to clean up the logs
  def terminate(:normal, _state) do
    :ok
  end

  def terminate(_, _state) do
    :ok
  end
end
