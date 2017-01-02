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
    This should be the human readable atom version of the param.
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
  def get_fw_version, do: get_param(:param_version)

  @doc """
    Gets the current controller version
  """
  @spec get_os_version :: String.t
  def get_os_version do
    GenServer.call(Configuration, :get_version)
  end

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

  @spec get_lock(String.t) :: integer | nil
  def get_lock(string) when is_bitstring(string) do
    GenServer.call(Configuration, {:get_lock, string})
  end

  @spec add_lock(String.t) :: :ok
  def add_lock(string) when is_bitstring(string) do
    GenServer.cast(Configuration, {:add_lock, string})
  end

  @spec remove_lock(String.t) :: :ok | {:error, atom}
  def remove_lock(string) when is_bitstring(string) do
    GenServer.call(Configuration, {:remove_lock, string})
  end
end
