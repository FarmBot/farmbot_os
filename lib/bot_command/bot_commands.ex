defmodule Command do
  require Logger
  @moduledoc """
    BotCommands.
  """

  @doc """
    EMERGENCY STOP
    #TODO
  """
  def e_stop do
    Logger.debug("E STOP NOT WORKIND")
  end

  @doc """
    Home All (TODO: this might be broken)
  """
  def home_all(speed) do
    Logger.debug("HOME ALL")
    Command.move_absolute(0, 0, 0, speed)
  end

  @doc """
    Home x
    I dont think anything uses these.
  """
  def home_x() do
    NewHandler.block_send("F11")
  end

  @doc """
    Home y
  """
  def home_y() do
    NewHandler.block_send("F12")
  end

  @doc """
    Home z
  """
  def home_z() do
    NewHandler.block_send("F13")
  end

  @doc """
    Writes a pin high or low
  """
  def write_pin(pin, value, mode) do
    NewHandler.block_send "F41 P#{pin} V#{value} M#{mode}"
  end

  @doc """
    Moves to (x,y,z) point.
    Sets the bot status to given coords
    replies to the mqtt message that caused it (if one exists)
    adds the move to the command queue.
  """
  def move_absolute(x \\ 0,y \\ 0,z \\ 0,s \\ 100)
  def move_absolute(x, y, z, s) when x >= 0 and y >= 0 do
    NewHandler.block_send "G00 X#{x} Y#{y} Z#{z} S#{s}"
  end

  # When both x and y are negative
  def move_absolute(x, y, z, s) when x < 0 and y < 0 do
    NewHandler.block_send "G00 X#{0} Y#{0} Z#{z} S#{s}"
  end

  # when x is negative
  def move_absolute(x, y, z, s) when x < 0 do
    NewHandler.block_send "G00 X#{0} Y#{y} Z#{z} S#{s}"
  end

  # when y is negative
  def move_absolute(x, y, z, s ) when y < 0 do
    NewHandler.block_send "G00 X#{x} Y#{0} Z#{z} S#{s}"
  end

  @doc """
    Gets the current position
    then pipes into move_absolute
  """
  def move_relative(e)
  def move_relative({:x, s, move_by}) when is_integer move_by do
    [x,y,z] = BotState.get_current_pos
    move_absolute(x + move_by,y,z,s)
  end

  def move_relative({:y, s, move_by}) when is_integer move_by do
    [x,y,z] = BotState.get_current_pos
    move_absolute(x,y + move_by,z,s)
  end

  def move_relative({:z, s, move_by}) when is_integer move_by do
    [x,y,z] = BotState.get_current_pos
    move_absolute(x,y,z + move_by,s)
  end

  # This is a funky one. Only used in sequences right now.
  def move_relative(%{x: x_move_by, y: y_move_by, z: z_move_by, speed: speed})
  when is_integer x_move_by and
       is_integer y_move_by and
       is_integer z_move_by
  do
    [x,y,z] = BotState.get_current_pos
    move_absolute(x + x_move_by,y + y_move_by,z + z_move_by, speed)
  end

  @doc """
    Used when bootstrapping the bot.
    Reads pins 0-13 in digital mode.
  """
  def read_all_pins do
    spawn fn -> Enum.each(0..13, fn pin ->
      GenServer.call(NewHandler, {:send, "F42 P#{pin} M#{0}", self()})
    end) end
  end

    @doc """
      Used when bootstrapping the bot.
      Reads all the params.
    """
  def read_all_params do
    rel_params = [0,11,12,13,21,22,23,
                  31,32,33,41,42,43,51,
                  52,53,61,62,63,71,72,73]
    spawn fn -> Enum.each(rel_params, fn param ->
      GenServer.call(NewHandler, {:send, "F21 P#{param}", self()})
    end ) end
  end

  @doc """
    Reads a pin value.
  """
  def read_pin(pin, mode \\ 0) do
    BotState.set_pin_mode(pin, mode)
    NewHandler.block_send "F42 P#{pin} M#{mode}"
  end

  @doc """
    Reads a param. Needs the integer version of said param.
  """
  def read_param(param) when is_integer param do
    NewHandler.block_send "F21 P#{param}"
  end

  @doc """
    Update a param. Param needs to be an integer.
  """
  def update_param(param, value) when is_integer param do
    NewHandler.block_send "F22 P#{param} V#{value}"
    Command.read_param(param)
  end

  def update_param(nil, _value) do
    {:error, "Unknown param"}
  end
end
