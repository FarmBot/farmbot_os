defmodule Farmbot.BotState do
  @moduledoc """
    Functions to modifying Farmbot's state
    all in one convenient (and easy to spell) location.
  """

  require Logger
  alias Farmbot.CeleryScript.Ast.Context

  @typedoc false
  @type context :: Context.t

  @doc """
    Gets the current position of the bot. Returns [x,y,z]
  """
  @spec get_current_pos(context) :: [integer, ...]
  def get_current_pos(%Context{} = context), do: GenServer.call(context.hardware, :get_current_pos)

  @doc """
    Sets the position to givin position.
  """
  @spec set_pos(context, integer,integer,integer) :: :ok
  def set_pos(%Context{} = context, x, y, z)
  when is_integer(x) and is_integer(y) and is_integer(z) do
    GenServer.cast(context.hardware, {:set_pos, {x, y, z}})
  end

  @doc """
    Sets a pin under the given value
  """
  @spec set_pin_value(context, integer, integer) :: :ok
  def set_pin_value(%Context{} = context, pin, value) when is_integer(pin) and is_integer(value) do
    GenServer.cast(context.hardware, {:set_pin_value, {pin, value}})
  end

  @doc """
    Sets a mode for a particular pin.
    This should happen before setting the value if possible.
  """
  @spec set_pin_mode(context, integer, 0 | 1) :: :ok
  def set_pin_mode(%Context{} = context, pin, mode)
  when is_integer(pin) and is_integer(mode) do
    GenServer.cast(context.hardware, {:set_pin_mode, {pin, mode}})
  end

  @doc """
    Sets a param to a particular value.
    This should be the human readable string version of the param.
  """
  @spec set_param(context, atom, integer) :: :ok
  def set_param(%Context{} = context, param, value) when is_atom(param) do
    GenServer.cast(context.hardware, {:set_param, {param, value}})
  end

  @doc """
    Sets the current end stops
  """
  @spec set_end_stops(context, Farmbot.BotState.Hardware.State.end_stops) :: :ok
  def set_end_stops(%Context{} = context, {xa,xb,ya,yb,za,zc}) do
    GenServer.cast(context.hardware, {:set_end_stops, {xa,xb,ya,yb,za,zc}})
  end

  @doc """
    Gets the map of every param.
    Useful for resetting params if the arduino flops
  """
  @spec get_all_mcu_params(context) :: Farmbot.BotState.Hardware.State.mcu_params
  def get_all_mcu_params(%Context{} = context) do
    GenServer.call(context.hardware, :get_all_mcu_params)
  end

  @doc """
    gets the value of a pin.
  """
  @spec get_pin(context, integer) :: %{mode: 0 | 1,   value: number}
  def get_pin(%Context{} = context, pin_number) when is_integer(pin_number) do
    GenServer.call(context.hardware, {:get_pin, pin_number})
  end

  @doc """
    Gets the current firmware version
    This is just a shortcut
  """
  @spec get_fw_version(context)  :: String.t
  def get_fw_version(%Context{} = context), do: GenServer.call(context.configuration, :get_fw_version)

  @doc """
    Set the version
  """
  @spec set_fw_version(context, binary) :: no_return
  def set_fw_version(%Context{} = context, v),
    do: GenServer.cast(context.configuration, {:update_info, :firmware_version, v})

  @doc """
    Gets the current controller version
  """
  @spec get_os_version(context) :: String.t
  def get_os_version(%Context{} = context), do: GenServer.call(context.configuration, :get_version)

  @doc """
    Gets the value of a hardware param
  """
  @spec get_param(context, atom) :: integer | nil
  def get_param(%Context{} = context, param), do: GenServer.call(context.hardware, {:get_param, param})

  @doc """
    Update a config under key
  """
  @spec update_config(context, String.t, any) :: :ok | {:error, atom}
  def update_config(%Context{} = context, config_key, value)
  when is_bitstring(config_key) do
    GenServer.call(context.configuration, {:update_config, config_key, value})
  end

  @doc """
    Gets the value stored under key.
  """
  @spec get_config(context, atom) :: nil | any
  def get_config(%Context{} = context, config_key) when is_atom(config_key) do
    GenServer.call(context.configuration, {:get_config, config_key})
  end

  @doc """
    Adds or updates a environment variable for Farmwares
    takes either a key and a value, or a map of keys and values.
    Creates new keys, or updates existing ones.
  """
  @spec set_user_env(context, String.t, String.t) :: boolean
  def set_user_env(%Context{} = context, key, val) do
    GenServer.call(context.configuration,
      {:update_config, "user_env", Map.new([{key, val}])})
  end

  @spec set_user_env(context, map) :: boolean
  def set_user_env(%Context{} = context, map) when is_map(map) do
    GenServer.call(context.configuration, {:update_config, "user_env", map})
  end

  @doc """
    Locks the bot
  """
  @spec lock_bot(context) :: :ok | no_return
  def lock_bot(%Context{} = context) do
    GenServer.cast(context.configuration, {:update_info, :locked, true})
  end

  @doc """
    Unlocks the bot
  """
  @spec unlock_bot(context) :: :ok | no_return
  def unlock_bot(%Context{} = context) do
    GenServer.cast(context.configuration, {:update_info, :locked, false})
  end

  @doc """
    Checks the bots lock status
  """
  @spec locked?(context) :: boolean
  def locked?(%Context{} = context) do
    GenServer.call(context.configuration, :locked?)
  end

  @doc """
    Sets the bots state of weather we need to sync or not.
  """
  @type sync_msg :: Configuration.sync_msg
  @spec set_sync_msg(context, sync_msg) :: :ok
  def set_sync_msg(context, sync_msg)

  def set_sync_msg(%Context{} = ctx, :sync_error = thing), do: do_set_sync_msg(ctx, thing)
  def set_sync_msg(%Context{} = ctx, :sync_now = thing),   do: do_set_sync_msg(ctx, thing)
  def set_sync_msg(%Context{} = ctx, :syncing = thing),    do: do_set_sync_msg(ctx, thing)
  def set_sync_msg(%Context{} = ctx, :unknown = thing),    do: do_set_sync_msg(ctx, thing)
  def set_sync_msg(%Context{} = ctx, :locked = thing),     do: do_set_sync_msg(ctx, thing)
  def set_sync_msg(%Context{} = ctx, :synced = thing),     do: do_set_sync_msg(ctx, thing)

  defp do_set_sync_msg(%Context{} = context, thing),
    do: GenServer.cast(context.configuration, {:update_info, :sync_status, thing})

end
