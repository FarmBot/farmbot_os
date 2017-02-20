defmodule Farmbot.BotState.Configuration do
  @moduledoc """
    Stores the configuration of the bot.
  """

  use GenServer
  require Logger
  alias Farmbot.StateTracker
  @behaviour StateTracker
  use StateTracker,
    name: __MODULE__,
    model:
    [
      locks: [],
      configuration: %{
        user_env: %{},
        os_auto_update: false,
        fw_auto_update: false,
        timezone:       nil,
        steps_per_mm_x: 10,
        steps_per_mm_y: 10,
        steps_per_mm_z: 50,
        distance_mm_x: 1500,
        distance_mm_y: 3000,
        distance_mm_z: 800
      },
      informational_settings: %{
        controller_version: "loading...",
        compat_version: -1,
        target: "loading...",
        private_ip: nil,
        throttled: "loading...",
        commit: "loading...",
        synced: false
       }
    ]

  @type args
    :: %{compat_version: integer,
         target: String.t,
         version: String.t,
         commit: String.t}
  @type state ::
    %State{
      locks: [any],
      configuration: %{
        user_env: map,
        os_auto_update: boolean,
        fw_auto_update: boolean,
        timezone: String.t,
        steps_per_mm_x: integer,
        steps_per_mm_y: integer,
        steps_per_mm_z: integer,
        distance_mm_x: integer,
        distance_mm_y: integer,
        distance_mm_z: integer
      },
      informational_settings: map # TODO type this
    }

  @spec load(args) :: {:ok, state} | {:error, atom}
  def load(
    %{compat_version: compat_version,
      target: target,
      version: version,
      commit: commit})
  do
    initial = %State{
      informational_settings: %{
        controller_version: version,
        compat_version: compat_version,
        target: target,
        private_ip: "loading...",
        throttled: get_throttled(),
        commit: commit
      }
    }
        with {:ok, user_env} <- get_config("user_env"),
         {:ok, os_a_u} <- get_config("os_auto_update"),
         {:ok, fw_a_u}   <- get_config("fw_auto_update"),
         {:ok, timezone} <- get_config("timezone"),
         {:ok, spm_x} <- get_config("steps_per_mm_x"),
         {:ok, spm_y} <- get_config("steps_per_mm_y"),
         {:ok, spm_z} <- get_config("steps_per_mm_z"),
         {:ok, len_x} <- get_config("distance_mm_x"),
         {:ok, len_y} <- get_config("distance_mm_y"),
         {:ok, len_z} <- get_config("distance_mm_z")
         do
           new_state =
             %State{initial | configuration: %{
                  user_env: user_env,
                  os_auto_update: os_a_u,
                  fw_auto_update: fw_a_u,
                  timezone: timezone,
                  steps_per_mm_x: spm_x,
                  steps_per_mm_y: spm_y,
                  steps_per_mm_z: spm_z,
                  distance_mm_x:  len_x,
                  distance_mm_y:  len_y,
                  distance_mm_z:  len_z }}
           {:ok, new_state}
         end
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
    new_config = Map.put(state.configuration, :os_auto_update, value)
    new_state = %State{state | configuration: new_config}
    put_config("os_auto_update", value)
    dispatch true, new_state
  end

  def handle_call({:update_config, "fw_auto_update", f_value},
   _from, %State{} = state) do
    value = cond do
      f_value == 1 -> true
      f_value == 0 -> false
      is_boolean(f_value) -> f_value
    end
    new_config = Map.put(state.configuration, :fw_auto_update, value)
    new_state = %State{state | configuration: new_config}
    put_config("fw_auto_update", value)
    dispatch true, new_state
  end

  def handle_call({:update_config, "timezone", value}, _from, %State{} = state)
  when is_bitstring(value) do
    new_config = Map.put(state.configuration, :timezone, value)
    new_state = %State{state | configuration: new_config}
    put_config("timezone", value)
    dispatch true, new_state
  end

  def handle_call({:update_config, "steps_per_mm_x", val}, _, state) do
    config = state.configuration
    new_config = %{config | steps_per_mm_x: val}
    new_state = %{state | configuration: new_config}
    put_config("steps_per_mm_x", val)
    dispatch true, new_state
  end

  def handle_call({:update_config, "steps_per_mm_y", val}, _, state) do
    config = state.configuration
    new_config = %{config | steps_per_mm_y: val}
    new_state = %{state | configuration: new_config}
    put_config("steps_per_mm_y", val)
    dispatch true, new_state
  end

  def handle_call({:update_config, "steps_per_mm_z", val}, _, state) do
    config = state.configuration
    new_config = %{config | steps_per_mm_z: val}
    new_state = %{state | configuration: new_config}
    put_config("steps_per_mm_z", val)
    dispatch true, new_state
  end

  def handle_call({:update_config, "distance_mm_x", val}, _, state) do
    config = state.configuration
    new_config = %{config | distance_mm_x: val}
    new_state = %{state | configuration: new_config}
    put_config("distance_mm_x", val)
    dispatch true, new_state
  end

  def handle_call({:update_config, "distance_mm_y", val}, _, state) do
    config = state.configuration
    new_config = %{config | distance_mm_y: val}
    new_state = %{state | configuration: new_config}
    put_config("distance_mm_y", val)
    dispatch true, new_state
  end

  def handle_call({:update_config, "distance_mm_z", val}, _, state) do
    config = state.configuration
    new_config = %{config | distance_mm_z: val}
    new_state = %{state | configuration: new_config}
    put_config("distance_mm_z", val)
    dispatch true, new_state
  end

  def handle_call({:update_config, "user_env", map}, _from, %State{} = state) do
    config = state.configuration
    f = Map.merge(config.user_env, map)
    new_config = %{config | user_env: f}
    new_state = %{state | configuration: new_config}
    put_config("user_env", f)
    dispatch true, new_state
  end

  def handle_call({:update_config, key, _value}, _from, %State{} = state) do
    Logger.error(
    ">> got an invalid configuration in Configuration tracker: #{inspect key}")
    dispatch false, state
  end

  # Allow the frontend to do stuff again.
  def handle_call({:remove_lock, string}, _from,  %State{} = state) do
    # Get the index of the lock
    maybe_index =
      Enum.find_index(state.locks, fn(%{reason: str}) -> str == string end)
    # If we got an index, dispatch it.
    if is_integer(maybe_index) do
      new_state =
        %State{state | locks: List.delete_at(state.locks, maybe_index)}

      dispatch :ok, new_state
    else
      # if not something is wrong, just crash.
      dispatch {:error, :no_index}, state
    end
  end

  def handle_call({:get_lock, string}, _from, %State{} = state) do
    # i could crash here, but eh.
    maybe_index =
      Enum.find_index(state.locks, fn(%{reason: str}) -> str == string end)
    dispatch(maybe_index, state)
  end

  def handle_call(:get_version, _from, %State{} = state) do
    dispatch(state.informational_settings.controller_version, state)
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
    new_info = Map.put(state.informational_settings, key, value)
    new_state = %State{state | informational_settings: new_info}
    dispatch new_state
  end

  # Lock the frontend from doing stuff
  def handle_cast({:add_lock, string}, %State{} = state) do
    maybe_index =
      Enum.find_index(state.locks, fn(%{reason: str}) -> str == string end)
    # check if this lock already exists.
    case maybe_index do
      nil ->
        new_state = %State{locks: state.locks ++ [%{reason: string}]}
        dispatch new_state
      _int ->
        dispatch state
    end
  end

  def handle_cast(event, %State{} = state) do
    Logger.error ">> got an unhandled cast in Configuration: #{inspect event}"
    dispatch state
  end

  defp get_throttled do
    if File.exists?("/usr/bin/vcgencmd") do
      {output, 0} = System.cmd("vcgencmd", ["get_throttled"])
      [_, throttled] =
        output
        |> String.strip
        |> String.split("=")
      throttled
    else
      "0xDEVELOPMENT"
    end
  end
end
