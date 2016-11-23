defmodule JoyStick do
  use GenServer
  require Logger

  @doc """
    Example:
      iex> {:ok, pid} = JoyStick.start_link "ttyUSB1"
  """
  def start_link(tty) do
    GenServer.start_link __MODULE__, tty, make: Module.concat(JoyStick, "_#{tty}")
  end

  def init(tty) do
    Process.flag(:trap_exit, true)
    {:ok, nerves} = Nerves.UART.start_link
    Nerves.UART.open(nerves, tty, speed: 115200, active: true)
    Nerves.UART.configure(nerves,
                          framing: {Nerves.UART.Framing.Line, separator: "\r\n"},
                          rx_framing_timeout: 500)
    {:ok, {nil, nil}}
  end

  def handle_call(:state, _from, state), do: {:reply, state, state}

  def handle_info({:nerves_uart, nerves_tty,
    << up :: size(8),
       down :: size(8),
       left :: size(8),
       right :: size(8)>> = new_thing}, last_thing)
  when new_thing != last_thing do
    # there was a change.
    apply new_thing
  end

  def handle_info({:nerves_uart, nerves_tty,
    << down :: size(8),
       left :: size(8),
       right :: size(8)>>}, last_thing)
  do
    handle_info({:nerves_uart, nerves_tty,
    << "0",
       down :: size(8),
       left :: size(8),
       right :: size(8)>>}, last_thing)
  end

  def handle_info({:nerves_uart, nerves_tty,
    << up :: size(8),
       down :: size(8),
       left :: size(8),
       right :: size(8)>>}, last_thing)
 do
    # there was not a change.
    dispatch last_thing
  end

  def handle_info({:nerves_uart, nerves_tty,
    << down :: size(8),
       left :: size(8),
       right :: size(8)>>}, last_thing)
  do
    # there was not a change.
    dispatch last_thing
  end

  def handle_info({:nerves_uart, nerves_tty, message}, state) do
    Logger.debug "message on tty: #{nerves_tty}, message: #{inspect message}"
    dispatch state
  end

  def handle_info(:done, state), do: dispatch state

  def apply("1111"), do: dispatch "1111"

  def apply(<< up :: size(8),
               down :: size(8),
               left :: size(8),
               right :: size(8)>> = thing
           ) do
    spawn fn -> Command.move_relative %{x: p(up,down), y: p(left,right), z: 0, speed: 100 } end
    dispatch thing
  end

  # To fix 0 not showing up when it is the first character
  def apply(<< down :: size(8),
               left :: size(8),
               right :: size(8)>>
           ) do
    apply(<< "0",
             down :: size(8),
             left :: size(8),
             right :: size(8)>>)
  end

  def dispatch(thing) do
    {:noreply, thing}
  end

  def p(48, 48), do:  0  # This cant happen lol
  def p(49, 49), do:  0  # neither button is pushed
  def p(48,  _), do:  100 # up or left
  def p(_,  48), do: -100 # down or right
end
