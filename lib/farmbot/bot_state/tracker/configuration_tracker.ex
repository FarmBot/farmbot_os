defmodule Farmbot.BotState.Configuration do
  @moduledoc """
    Stores the configuration of the bot.
  """

  use GenServer
  require Logger
  alias Farmbot.BotState.StateTracker
  @behaviour StateTracker

  use StateTracker,
    name: __MODULE__,
    model:
    [
      configuration: %{
        timezone: nil,
        user_env: %{},
        os_auto_update: false,
        steps_per_mm_x: 10,
        steps_per_mm_y: 10,
        steps_per_mm_z: 50,
        distance_mm_x: 1500,
        distance_mm_y: 3000,
        distance_mm_z: 800,
      },
      informational_settings: %{
        locked: false,
        controller_version: "loading...",
        target: "loading...",
        commit: "loading...",
        sync_status: :sync_now,
        firmware_version: "Arduino Disconnected!"
       }
    ]
  @typedoc """
    The message for the sync button to display
  """
  @type sync_msg :: :sync_now | :syncing | :sync_error | :unknown | :locked
  @type state ::
    %State{
      configuration: %{
        timezone: nil | binary,
        user_env: map,
        os_auto_update: boolean,
        steps_per_mm_x: integer,
        steps_per_mm_y: integer,
        steps_per_mm_z: integer,
        distance_mm_x: integer,
        distance_mm_y: integer,
        distance_mm_z: integer,
        sync_status: sync_msg
      },
      informational_settings: %{
        locked: boolean,
        controller_version: binary,
        target: binary,
        commit: binary,
        sync_status: sync_msg,
        firmware_version: binary
       }
    }

  @version Mix.Project.config()[:version]
  @target  Mix.Project.config()[:target]
  @commit  Mix.Project.config()[:commit]

  @spec load() :: {:ok, state} | no_return
  def load do
    initial = %State{
      informational_settings: %{
        controller_version: @version,
        target: @target,
        commit: @commit,
        locked: false,
        sync_status: :sync_now,
        firmware_version: "Arduino Disconnected!"
      }
    }
    {:ok, user_env} = get_config("user_env")
    {:ok, os_a_u}   = get_config("os_auto_update")
    {:ok, spm_x}    = get_config("steps_per_mm_x")
    {:ok, spm_y}    = get_config("steps_per_mm_y")
    {:ok, spm_z}    = get_config("steps_per_mm_z")
    {:ok, len_x}    = get_config("distance_mm_x")
    {:ok, len_y}    = get_config("distance_mm_y")
    {:ok, len_z}    = get_config("distance_mm_z")
    {:ok, tz}       = get_config("timezone")
    new_state =
      %State{initial | configuration: %{
           user_env:             user_env,
           timezone:             tz,
           os_auto_update:       os_a_u,
           steps_per_mm_x:       spm_x,
           steps_per_mm_y:       spm_y,
           steps_per_mm_z:       spm_z,
           distance_mm_x:        len_x,
           distance_mm_y:        len_y,
           distance_mm_z:        len_z
    }}
    {:ok, new_state}
  end

  # This call should probably be a cast actually, and im sorry.
  # Returns true for configs that exist and are the correct typpe,
  # and false for anything else
  def handle_call({:update_config, "os_auto_update", f_value},
   _from, %State{} = state) do
    value = cond do
      f_value == 1 -> true
      f_value == 0 -> false
      is_boolean(f_value) -> f_value
    end
    update_config(state, :os_auto_update, value)
  end

  def handle_call({:update_config, "steps_per_mm_x", val}, _, state) do
    update_config(state, :steps_per_mm_x, val)
  end

  def handle_call({:update_config, "steps_per_mm_y", val}, _, state) do
    update_config(state, :steps_per_mm_y, val)
  end

  def handle_call({:update_config, "steps_per_mm_z", val}, _, state) do
    update_config(state, :steps_per_mm_z, val)
  end

  def handle_call({:update_config, "distance_mm_x", val}, _, state) do
    update_config(state, :distance_mm_x, val)
  end

  def handle_call({:update_config, "distance_mm_y", val}, _, state) do
    update_config(state, :distance_mm_y, val)
  end

  def handle_call({:update_config, "distance_mm_z", val}, _, state) do
    update_config(state, :distance_mm_z, val)
  end

  def handle_call({:update_config, "timezone", val}, _, state) do
    update_config(state, :timezone, val)
  end

  def handle_call({:update_config, "user_env", map}, _from, %State{} = state) do
    config     = state.configuration
    f          = Map.merge(config.user_env, map)
    new_config = %{config | user_env: f}
    new_state  = %{state | configuration: new_config}
    put_config("user_env", f)
    dispatch true, new_state
  end

  def handle_call({:update_config, key, _value}, _from, %State{} = state) do
    Logger.error(
    ">> got an invalid configuration in Configuration tracker: #{inspect key}")
    dispatch false, state
  end

  def handle_call(:locked?, _, state) do
    dispatch state.informational_settings.locked, state
  end

  def handle_call(:get_version, _from, %State{} = state) do
    dispatch(state.informational_settings.controller_version, state)
  end

  def handle_call(:get_fw_version, _from, state) do
    dispatch(state.informational_settings.firmware_version, state)
  end

  def handle_call({:get_config, key}, _from, %State{} = state)
  when is_atom(key) do
    dispatch Map.get(state.configuration, key), state
  end

  def handle_call(event, _from, %State{} = state) do
    Logger.error ">> got an unhandled call in " <>
                 "Configuration tracker: #{inspect event}"
    dispatch :unhandled, state
  end

  def handle_cast({:update_info, key, value}, %State{} = state) do
    dispatch do_update_info(state, key, value)
  end

  def handle_cast({:update_sync_message, thing}, %State{} = state) do
    if state.informational_settings.locked do
      dispatch state
    else
      dispatch do_update_info(state, :sync_status, thing)
    end
  end

  def handle_cast(event, %State{} = state) do
    Logger.error ">> got an unhandled cast in Configuration: #{inspect event}"
    dispatch state
  end

  @spec do_update_info(State.t, binary | atom, term) :: State.t
  defp do_update_info(%State{} = state, key, value) do
    new_info = Map.put(state.informational_settings, key, value)
    %State{state | informational_settings: new_info}
  end

  defp update_config(state, key, val) do
    config = state.configuration
    new_config = %{config | key => val}
    new_state = %{state | configuration: new_config}
    put_config(to_string(key), val)
    dispatch true, new_state
  end
end
