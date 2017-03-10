alias Farmbot.BotState.Hardware,      as: Hardware
alias Farmbot.BotState.Configuration, as: Configuration

defmodule Farmbot.BotState do
  require Logger
  @moduledoc """
    Functions to modifying Farmbot's state
    all in one convenient (and easy to spell) location.
  """

  @doc """
    Gets the current position of the bot. Returns [x,y,z]
  """
  @spec get_current_pos() :: [integer, ...]
  def get_current_pos, do: GenServer.call(Hardware, :get_current_pos)

  @doc """
    Sets the position to givin position.
  """
  @spec set_pos(integer,integer,integer) :: :ok
  def set_pos(x, y, z)
  when is_integer(x) and is_integer(y) and is_integer(z) do
    GenServer.cast(Hardware, {:set_pos, {x, y, z}})
  end

  @doc """
    Sets a pin under the given value
  """
  @spec set_pin_value(integer, integer) :: :ok
  def set_pin_value(pin, value) when is_integer(pin) and is_integer(value) do
    GenServer.cast(Hardware, {:set_pin_value, {pin, value}})
  end

  @doc """
    Sets a mode for a particular pin.
    This should happen before setting the value if possible.
  """
  @spec set_pin_mode(integer, 0 | 1) :: :ok
  def set_pin_mode(pin, mode)
  when is_integer(pin) and is_integer(mode) do
    GenServer.cast(Hardware, {:set_pin_mode, {pin, mode}})
  end

  @doc """
    Sets a param to a particular value.
    This should be the human readable string version of the param.
  """
  @spec set_param(atom, integer) :: :ok
  def set_param(param, value) when is_atom(param) do
    GenServer.cast(Hardware, {:set_param, {param, value}})
  end

  @doc """
    Sets the current end stops
  """
  @spec set_end_stops(Hardware.State.end_stops) :: :ok
  def set_end_stops({xa,xb,ya,yb,za,zc}) do
    GenServer.cast(Hardware, {:set_end_stops, {xa,xb,ya,yb,za,zc}})
  end

  @doc """
    Gets the map of every param.
    Useful for resetting params if the arduino flops
  """
  @spec get_all_mcu_params :: Hardware.State.mcu_params
  def get_all_mcu_params do
    GenServer.call(Hardware, :get_all_mcu_params)
  end

  @doc """
    gets the value of a pin.
  """
  @spec get_pin(integer) :: %{mode: 0 | 1,   value: number}
  def get_pin(pin_number) when is_integer(pin_number) do
    GenServer.call(Hardware, {:get_pin, pin_number})
  end

  @doc """
    Gets the current firmware version
    This is just a shortcut
  """
  @spec get_fw_version :: String.t
  def get_fw_version, do: GenServer.call(Configuration, :get_fw_version)

  @doc """
    Set the version
  """
  @spec set_fw_version(binary) :: no_return
  def set_fw_version(v),
    do: GenServer.cast(Configuration, {:update_info, :firmware_version, v})

  @doc """
    Gets the current controller version
  """
  @spec get_os_version :: String.t
  def get_os_version, do: GenServer.call(Configuration, :get_version)

  @doc """
    Gets the value of a param
  """
  @spec get_param(atom) :: integer | nil
  def get_param(param), do: GenServer.call(Hardware, {:get_param, param})

  @doc """
    Update a config under key
  """
  @spec update_config(String.t, any) :: :ok | {:error, atom}
  def update_config(config_key, value)
  when is_bitstring(config_key) do
    GenServer.call(Configuration, {:update_config, config_key, value})
  end

  @doc """
    Gets the value stored under key.
  """
  @spec get_config(atom) :: nil | any
  def get_config(config_key) when is_atom(config_key) do
    GenServer.call(Configuration, {:get_config, config_key})
  end

  @doc """
    Adds or updates a environment variable for Farmwares
    takes either a key and a value, or a map of keys and values.
    Creates new keys, or updates existing ones.
  """
  @spec set_user_env(String.t, String.t) :: boolean
  def set_user_env(key, val) do
    GenServer.call(Configuration,
      {:update_config, "user_env", Map.new([{key, val}])})
  end

  @spec set_user_env(map) :: boolean
  def set_user_env(map) when is_map(map) do
    GenServer.call(Configuration, {:update_config, "user_env", map})
  end

  @doc """
    Locks the bot
  """
  @spec lock_bot :: :ok | no_return
  def lock_bot do
    GenServer.cast(Configuration, {:update_info, :locked, true})
  end

  @doc """
    Unlocks the bot
  """
  @spec unlock_bot :: :ok | no_return
  def unlock_bot do
    GenServer.cast(Configuration, {:update_info, :locked, false})
  end

  @doc """
    Checks the bots lock status
  """
  @spec locked? :: boolean
  def locked? do
    GenServer.call(Configuration, :locked?)
  end

  @doc """
    Sets the bots state of weather we need to sync or not.
  """
  @type sync_msg :: Configuration.sync_msg
  @spec set_sync_msg(sync_msg) :: :ok
  def set_sync_msg(sync_msg)
  def set_sync_msg(:synced = thing),
    do: GenServer.cast(Configuration, {:update_info, :sync_status, thing})
  def set_sync_msg(:sync_now = thing),
    do: GenServer.cast(Configuration, {:update_info, :sync_status, thing})
  def set_sync_msg(:syncing = thing),
    do: GenServer.cast(Configuration, {:update_info, :sync_status, thing})
  def set_sync_msg(:sync_error = thing),
    do: GenServer.cast(Configuration, {:update_info, :sync_status, thing})
  def set_sync_msg(:unknown = thing),
    do: GenServer.cast(Configuration, {:update_info, :sync_status, thing})
end
