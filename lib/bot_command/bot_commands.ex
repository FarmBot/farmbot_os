defmodule Command do
  require Logger
  @log_tag "BotControl"
  @moduledoc """
    BotCommands.
  """

  @doc """
    EMERGENCY STOP
    #TODO
  """
  def e_stop do
    msg = "E STOPPING!"
    Logger.debug(msg)
    RPCMessageHandler.log(msg, [:error_toast, :error_ticker], [@log_tag])
  end

  @doc """
    Home All (TODO: this might be broken)
  """
  def home_all(speed \\ nil) do
    msg = "HOME ALL"
    Logger.debug(msg)
    RPCMessageHandler.log(msg, [], [@log_tag])
    Command.move_absolute(0, 0, 0, speed || BotState.get_config(:steps_per_mm))
  end

  @doc """
    Home x
    I dont think anything uses these.
  """
  def home_x() do
    msg = "HOME X"
    Logger.debug(msg)
    RPCMessageHandler.log(msg, [], [@log_tag])
    NewHandler.block_send("F11")
  end

  @doc """
    Home y
  """
  def home_y() do
    msg = "HOME Y"
    Logger.debug(msg)
    RPCMessageHandler.log(msg, [], [@log_tag])
    NewHandler.block_send("F12")
  end

  @doc """
    Home z
  """
  def home_z() do
    msg = "HOME Z"
    Logger.debug(msg)
    RPCMessageHandler.log(msg, [], [@log_tag])
    NewHandler.block_send("F13")
  end

  @doc """
    Writes a pin high or low
  """
  def write_pin(pin, value, mode)
  when is_integer(pin) and is_integer(value) and is_integer(mode) do
    BotState.set_pin_mode(pin, mode)
    BotState.set_pin_value(pin, value)
    NewHandler.block_send("F41 P#{pin} V#{value} M#{mode}") |> logmsg("write_pin")
  end

  @doc """
    Moves to (x,y,z) point.
  """
  def move_absolute(x ,y ,z ,s \\ nil)
  def move_absolute(x, y, z, s) do
    msg = "Moving to X#{x} Y#{y} Z#{z}"
    Logger.debug(msg)
    RPCMessageHandler.log(msg, [], [@log_tag])
    NewHandler.block_send("G00 X#{x} Y#{y} Z#{z} S#{s || BotState.get_config(:steps_per_mm)}")
    |> logmsg("Movement")
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
    Reads all the params.
    TODO: Make these not magic numbers.
  """
  def read_all_params(params \\ [0,11,12,13,21,22,23,
                                 31,32,33,41,42,43,51,
                                 52,53,61,62,63,71,72,73])
  when is_list(params) do
    case Enum.partition(params, fn param ->
      GenServer.call(NewHandler, {:send, "F21 P#{param}", self()})
      :done == NewHandler.block(2500)
    end) do
      {_, []} -> :ok
      {_, failed_params} -> read_all_params(failed_params)
       _ -> :fail
    end
  end

  @doc """
    Reads a pin value.
    mode can be 0 (digital) or 1 (analog)
  """
  def read_pin(pin, mode \\ 0) when is_integer(pin) do
    BotState.set_pin_mode(pin, mode)
    NewHandler.block_send("F42 P#{pin} M#{mode}") |> logmsg("read_pin")
  end

  @doc """
    gets the current value, and then toggles it.
  """
  def toggle_pin(pin) when is_integer(pin) do
    pinMap = BotState.get_pin(pin)
    case pinMap do
      %{mode: 0, value: 1 } ->
        write_pin(pin, 0, 0)
      %{mode: 0, value: 0 } ->
        write_pin(pin, 1, 0)
      nil ->
        read_pin(pin, 0)
        toggle_pin(pin)
      _ -> :fail
    end
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

  defp logmsg(:done, command) when is_bitstring(command) do
    RPCMessageHandler.log("#{command} Complete", [],[@log_tag])
    :done
  end

  defp logmsg(other, command) when is_bitstring(command) do
    Logger.error("#{command} Failed")
    RPCMessageHandler.log("#{command} Failed", [:error_toast, :error_ticker],[@log_tag])
    other
  end
end
