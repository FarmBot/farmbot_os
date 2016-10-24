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

  def handle_cast({:idle}, state) do
    {:noreply, %{nerves: state.nerves, current: nil, log: []}}
  end

  def handle_cast({:done}, %{nerves: nerves, current: {_current_str, pid}, log: log}) do
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

  def handle_cast({:done}, state) do
    {:noreply, %{nerves: state.nerves, current: nil, log: []}}
  end

  def handle_cast({:received}, state) do
    {:noreply, state}
  end

  def handle_cast({:report_pin_value, params}, state) do
    ["P"<>pin, "V"<>value] = String.split(params, " ")
    Logger.debug("pin#{pin}: #{value}")
    BotState.set_pin_value(String.to_integer(pin), String.to_integer(value))
    {:noreply, state}
  end

  def handle_cast( {:report_current_position, position }, state) do
    [x, y, z] = parse_coords(position)
    Logger.debug("Reporting position #{inspect {x, y, z}}")
    BotState.set_pos(x,y,z)
    {:noreply, state}
  end

  def handle_cast({:report_parameter_value, param }, state) do
    [p, v] = String.split(param, " ")
    [_, real_param] = String.split(p, "P")
    [_, real_value] = String.split(v, "V")
    Logger.debug("Param: #{real_param}, Value: #{real_value}")
    real_param
    |> Gcode.parse_param
    |> Atom.to_string          # DON'T
    |> String.Casing.downcase  # DO
    |> String.to_atom          # THIS
    |> BotState.set_param(String.to_integer(real_value))
    {:noreply, state}
  end

  # TODO report end stops
  def handle_cast({:reporting_end_stops, stop_values }, state) do
    # Logger.debug("[gcode_handler] {:reporting_end_stops} stub: #{stop_values}")
    stop_values
    |> parse_stop_values
    |> Enum.each(&BotState.set_end_stop/1)
    {:noreply, state}
  end

  def handle_cast({:busy}, %{nerves: nerves, current: {cur_str, pid}, log: log}) do
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

  @doc """
  Example:
    iex> GcodeMessageHandler.parse_coords("X34 Y756 Z23")
    [34, 756, 23]
  """
  def parse_coords(position) when position |> is_binary do
    position
    |> String.split(" ")
    |> parse_coords
  end
  def parse_coords(["X" <> x,"Y" <> y, "Z" <> z]) do
    [x,y,z]
    |> Enum.map(&String.to_integer/1)
  end


  @doc """
  Example:
    iex> GcodeMessageHandler.parse_stop_values("XA0 XB0 YA0 YB0 ZA0 ZB0")
    [{"XA", "0"}, {"XB", "0"}, {"YA", "0"}, {"YB", "0"}, {"ZA", "0"}, {"ZB", "0"}]
  """
  def parse_stop_values(stop_values) when stop_values |> is_binary do
    # same thing here as parse_coords
    stop_values
    |> String.split(" ")
    |> parse_stop_values
  end
  def parse_stop_values(["XA"<>xa, "XB"<>xb,
                         "YA"<>ya, "YB"<>yb,
                         "ZA"<>za, "ZB"<>zb]) do
    [
      {"XA", xa}, {"XB", xb},
      {"YA", ya}, {"YB", yb},
      {"ZA", za}, {"ZB", zb},
    ]
  end

end
