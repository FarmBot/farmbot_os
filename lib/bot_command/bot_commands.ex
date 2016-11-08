defmodule Command do
  require Logger
  @log_tag "BotControl"
  @type command_output :: :done | :timeout | :error
  @moduledoc """
    BotCommands.
  """

  @doc """
    EMERGENCY STOP.
    This will happen in a pretty specific order.
    first: write an "E" to the serial line directly.
    second: stop any running sequences.
    third: Probably write another E.
    fourth: pause running regimens and other stuff that might do serial stuff
            on a timer.
  """
  def e_stop do
    msg = "E STOPPING!"
    Logger.debug(msg)
    RPC.MessageHandler.log(msg, [:error_toast, :error_ticker], [@log_tag])
    Serial.Handler.e_stop
    FarmEventManager.e_stop
  end

  @doc """
    resume from an e stop
  """
  @spec resume() :: :ok | :fail
  def resume do
    RPC.MessageHandler.log("Bot Back Up and Running!", [:ticker], [@log_tag])
    Serial.Handler.resume
    params = BotState.get_status.mcu_params
    case Enum.partition(params, fn({param, value}) ->
      param_int = Gcode.Parser.parse_param(param)
      Command.update_param(param_int, value)
    end)
    do
      {_, []} ->
        :ok
      {_, failed} ->
        Logger.error("Param setting failed! #{inspect failed}")
        :fail
    end
  end

  @doc """
    Home All
  """
  @spec home_all(number | nil) :: command_output
  def home_all(speed \\ nil) do
    msg = "HOME ALL"
    Logger.debug(msg)
    RPC.MessageHandler.log(msg, [], [@log_tag])
    Command.move_absolute(0, 0, 0, speed || BotState.get_config(:steps_per_mm))
  end

  @doc """
    Home x
    I dont think anything uses this.
  """
  def home_x() do
    msg = "HOME X"
    Logger.debug(msg)
    RPC.MessageHandler.log(msg, [], [@log_tag])
    Gcode.Handler.block_send("F11")
  end

  @doc """
    Home y
  """
  def home_y() do
    msg = "HOME Y"
    Logger.debug(msg)
    RPC.MessageHandler.log(msg, [], [@log_tag])
    Gcode.Handler.block_send("F12")
  end

  @doc """
    Home z
  """
  def home_z() do
    msg = "HOME Z"
    Logger.debug(msg)
    RPC.MessageHandler.log(msg, [], [@log_tag])
    Gcode.Handler.block_send("F13")
  end

  @doc """
    Writes a pin high or low
  """
  @spec write_pin(number, number, number) :: command_output
  def write_pin(pin, value, mode)
  when is_integer(pin) and is_integer(value) and is_integer(mode) do
    BotState.set_pin_mode(pin, mode)
    BotState.set_pin_value(pin, value)
    Gcode.Handler.block_send("F41 P#{pin} V#{value} M#{mode}") |> logmsg("write_pin")
  end

  @doc """
    Moves to (x,y,z) point.
  """
  @spec move_absolute(number, number, number, number | nil) :: command_output
  def move_absolute(x ,y ,z ,s \\ nil)
  def move_absolute(x, y, z, s) do
    msg = "Moving to X#{x} Y#{y} Z#{z}"
    Logger.debug(msg)
    RPC.MessageHandler.log(msg, [], [@log_tag])
    Gcode.Handler.block_send("G00 X#{x} Y#{y} Z#{z} S#{s || BotState.get_config(:steps_per_mm)}")
    |> logmsg("Movement")
  end

  @doc """
    Gets the current position
    then pipes into move_absolute
  """
  @spec move_relative(
  {:x, number | nil, number} |
  {:y, number | nil, number} |
  {:z, number | nil, number} |
  %{x: number, y: number, z: number, speed: number | nil}) :: command_output
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
  when is_integer(x_move_by) and
       is_integer(y_move_by) and
       is_integer(z_move_by)
  do
    [x,y,z] = BotState.get_current_pos
    move_absolute(x + x_move_by,y + y_move_by,z + z_move_by, speed)
  end

  @doc """
    Used when bootstrapping the bot.
    Reads all the params.
    TODO: Make these not magic numbers.
  """
  @spec read_all_params(list(number)) :: :ok | :fail
  def read_all_params(params \\ [0,11,12,13,21,22,23,
                                 31,32,33,41,42,43,51,
                                 52,53,61,62,63,71,72,73])
  when is_list(params) do
    case Enum.partition(params, fn param ->
      GenServer.call(Gcode.Handler, {:send, "F21 P#{param}", self()})
      :done == Gcode.Handler.block(2500)
    end) do
      {_, []} -> :ok
      {_, failed_params} -> read_all_params(failed_params)
    end
  end

  @doc """
    Reads a pin value.
    mode can be 0 (digital) or 1 (analog)
  """
  @spec read_pin(number, 0 | 1) :: command_output
  def read_pin(pin, mode \\ 0) when is_integer(pin) do
    BotState.set_pin_mode(pin, mode)
    Gcode.Handler.block_send("F42 P#{pin} M#{mode}")
    |> logmsg("read_pin")
  end

  @doc """
    gets the current value, and then toggles it.
  """
  @spec toggle_pin(number) :: command_output
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
  @spec read_param(number) :: command_output
  def read_param(param) when is_integer param do
    Gcode.Handler.block_send "F21 P#{param}"
  end

  @doc """
    Update a param. Param needs to be an integer.
  """
  @spec update_param(number | nil, number) :: command_output
  def update_param(param, value) when is_integer param do
    Gcode.Handler.block_send "F22 P#{param} V#{value}"
    Command.read_param(param)
  end

  def update_param(nil, _value) do
    {:error, "Unknown param"}
  end

  @spec logmsg(command_output, String.t) :: command_output
  defp logmsg(:done, command) when is_bitstring(command) do
    RPC.MessageHandler.log("#{command} Complete", [],[@log_tag])
    :done |> Command.Tracker.beep
  end

  defp logmsg(other, command) when is_bitstring(command) do
    Logger.error("#{command} Failed")
    RPC.MessageHandler.log("#{command} Failed", [:error_toast, :error_ticker],[@log_tag])
    other |> Command.Tracker.beep
  end
end
