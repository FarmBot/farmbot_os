alias Experimental.{GenStage}
defmodule GcodeMessageHandler do
  use GenStage
  require Logger

  def start_link() do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    {:consumer, :ok, subscribe_to: [SerialMessageManager]}
  end

  def handle_events(events, _from, state) do
    for event <- events do
      do_handle(event)
    end
    {:noreply, [], state}
  end

  # I think this is supposed to be somewhere else.
  def do_handle({:send, str}) do
    GenServer.cast(UartHandler, {:send, str})
  end

  # This is the heartbeat messge.
  def do_handle({:gcode, {:idle} }) do
    BotStatus.busy false
  end

  # The opposite of the below command?
  def do_handle({:gcode, {:done } }) do
    BotStatus.busy false
    RPCMessageHandler.send_status
  end

  # I'm not entirely sure what this is.
  def do_handle({:gcode, {:received } }) do
    BotStatus.busy true
  end

  def do_handle({:gcode, { :report_pin_value, params }}) do
    ["P"<>pin, "V"<>value] = String.split(params, " ")
    Logger.debug("pin#{pin}: #{value}")
    BotStatus.set_pin(String.to_integer(pin), String.to_integer(value))
  end

  # TODO report end stops
  def do_handle({:gcode, {:reporting_end_stops, stop_values }}) do
    # Logger.debug("[gcode_handler] {:reporting_end_stops} stub: #{stop_values}")
    stop_values
    |> parse_stop_values
    |> Enum.each(&BotStatus.set_end_stop/1)
  end

  def do_handle({:gcode, { :report_current_position, position }}) do
    [x, y, z] = parse_coords(position)
    BotStatus.set_pos(x,y,z)
  end

  def do_handle({:gcode, {:report_parameter_value, param }}) do
    [p, v] = String.split(param, " ")
    [_, real_p] = String.split(p, "P")
    [_, real_v] = String.split(v, "V")
    Logger.debug("Param: #{real_p}, Value: #{real_v}")
    real_p
    |> Gcode.parse_param
    |> Atom.to_string
    |> String.downcase
    |> BotStatus.set_param(real_v)
  end

  def do_handle({:gcode, {:busy}}) do
    BotStatus.busy true
  end

  def do_handle({:gcode, {:debug_message, "stopped"}} ) do
    # BotStatus.busy false
  end

  # Serial sending a debug message. Print it.
  def do_handle({:gcode, {:debug_message, message}} ) do
    Logger.debug("Debug message from arduino: #{message}")
  end

  # Unhandled gcode message
  def do_handle({:gcode, {:unhandled_gcode, code}}) do
    Logger.debug("[gcode_handler] Broken code? : #{inspect code}")
  end

  # Catch all for serial messages
  def do_handle({:gcode, message}) do
    Logger.debug("[gcode_handler] Unhandled Serial Gcode: #{inspect message}")
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
