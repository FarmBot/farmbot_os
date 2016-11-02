defmodule NewHandler do
  require Logger
  use GenServer

  def start_link(nerves) do
    GenServer.start_link(__MODULE__, nerves, name: __MODULE__)
  end

  def init(nerves) do
    {:ok, %{nerves: nerves, current: nil, log: []}}
  end

  def handle_cast({:debug_message, str}, state) do
    Logger.debug("Debug Message from arduino: #{str}")
    {:noreply, state}
  end

  def handle_cast({:idle, _}, state) do
    {:noreply, %{nerves: state.nerves, current: nil, log: []}}
  end

  def handle_cast({:done, _}, %{nerves: nerves, current: {_current_str, pid}, log: log}) do
    send(pid, :done)
    RPCMessageHandler.send_status
    case List.first(log) do
      {nextstr, new_pid} ->
        UartHandler.write(nerves,nextstr)
        {:noreply, %{nerves: nerves, current: {nextstr, new_pid}, log: log -- [{nextstr, new_pid}] }}
      nil ->
        {:noreply, %{nerves: nerves, current: nil, log: []} }
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
    Logger.debug("pin#{pin}: #{value}")
    BotState.set_pin_value(pin, value)
    {:noreply, state}
  end

  def handle_cast( {:report_current_position, x,y,z, _ }, state) do
    Logger.debug("Reporting position #{inspect {x, y, z}}")
    BotState.set_pos(x,y,z)
    {:noreply, state}
  end

  def handle_cast({:report_parameter_value, param, value, _}, state)
  when is_atom(param) and is_integer(value) do
    Logger.debug("Param: #{param}, Value: #{value}")
    BotState.set_param(param, value)
    {:noreply, state}
  end

  # TODO report end stops
  def handle_cast({:reporting_end_stops, x1,x2,y1,y2,z1,z2,_ }, state) do
    Logger.warn("Set end stops valid: #{inspect {x1,x2,y1,y2,z1,z2}}")
    {:noreply, state}
  end

  # TODO report end stops
  def handle_cast({:reporting_end_stops, blah}, state) do
    Logger.warn("Set end stops valid: #{inspect blah}")
    {:noreply, state}
  end

  def handle_cast({:busy, _}, %{nerves: nerves, current: {cur_str, pid}, log: log}) do
    send(pid, :busy)
    Logger.debug("Arduino is busy")
    {:noreply, %{nerves: nerves, current: {cur_str, pid}, log: log}}
  end


  def handle_cast(event, state) do
    Logger.debug("unhandled gcode! #{inspect event}")
    {:noreply, state}
  end

  # If we arent waiting on anything right now. (current is nil and log is empty)
  def handle_call({:send, message, caller}, _from, %{ nerves: nerves, current: nil, log: [] }) do
    UartHandler.write(nerves,message)
    {:reply, :sending, %{nerves: nerves, current: {message, caller}, log: []} }
  end

  def handle_call({:send, message, caller}, _from, %{nerves: nerves, current: current, log: log}) do
    {:reply, :logging, %{nerves: nerves, current: current, log: log ++ [{message, caller}]} }
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def block_send(str, timeout\\ 10000) do
    GenServer.call(NewHandler,{ :send, str, self()})
    block(timeout)
  end

  def block(timeout) do
    receive do
      :done -> :done
      :busy -> block(timeout)
      error -> error
    after
      timeout -> :timeout
    end
  end
end
