defmodule FarmbotCore.BotState do
  @moduledoc "Central State accumulator."
  alias FarmbotCore.BotStateNG
  use GenServer

  @doc "Subscribe to BotState changes"
  def subscribe(bot_state_server \\ __MODULE__) do
    GenServer.call(bot_state_server, :subscribe)
  end

  @doc "Set job progress."
  def set_job_progress(bot_state_server \\ __MODULE__, name, progress) do
    GenServer.call(bot_state_server, {:set_job_progress, name, progress})
  end

  @doc "Add an enigma record to bot state."
  def set_enigma(bot_state_server \\ __MODULE__, enigma) do
    GenServer.call(bot_state_server, {:set_enigma, enigma})
  end

  @doc "Set a configuration value"
  def set_config_value(bot_state_server \\ __MODULE__, key, value) do
    GenServer.call(bot_state_server, {:set_config_value, key, value})
  end

  @doc "Sets user_env value"
  def set_user_env(bot_state_server \\ __MODULE__, key, value) do
    GenServer.call(bot_state_server, {:set_user_env, key, value})
  end

  @doc "Sets the location_data.position"
  def set_position(bot_state_server \\ __MODULE__, x, y, z) do
    GenServer.call(bot_state_server, {:set_position, x, y, z})
  end

  @doc "Sets the location_data.encoders_scaled"
  def set_encoders_scaled(bot_state_server \\ __MODULE__, x, y, z) do
    GenServer.call(bot_state_server, {:set_encoders_scaled, x, y, z})
  end

  @doc "Sets pins.pin.value"
  def set_pin_value(bot_state_server \\ __MODULE__, pin, value) do
    GenServer.call(bot_state_server, {:set_pin_value, pin, value})
  end

  @doc "Sets the location_data.encoders_raw"
  def set_encoders_raw(bot_state_server \\ __MODULE__, x, y, z) do
    GenServer.call(bot_state_server, {:set_encoders_raw, x, y, z})
  end

  @doc "Sets mcu_params[param] = value"
  def set_firmware_config(bot_state_server \\ __MODULE__, param, value) do
    GenServer.call(bot_state_server, {:set_firmware_config, param, value})
  end

  @doc "Sets informational_settings.locked = true"
  def set_firmware_locked(bot_state_server \\ __MODULE__) do
    GenServer.call(bot_state_server, {:set_firmware_locked, true})
  end

  @doc "Sets informational_settings.locked = false"
  def set_firmware_unlocked(bot_state_server \\ __MODULE__) do
    GenServer.call(bot_state_server, {:set_firmware_locked, false})
  end

  @doc "Sets informational_settings.firmware_version"
  def set_firmware_version(bot_state_server \\ __MODULE__, version) do
    GenServer.call(bot_state_server, {:set_firmware_version, version})
  end

  @doc "Sets informational_settings.busy"
  def set_firmware_busy(bot_state_server \\ __MODULE__, busy) do
    GenServer.call(bot_state_server, {:set_firmware_busy, busy})
  end

  @doc "Sets informational_settings.status"
  def set_sync_status(bot_state_server \\ __MODULE__, s)
      when s in ["sync_now", "syncing", "synced", "error"] do
    GenServer.call(bot_state_server, {:set_sync_status, s})
  end

  @doc "sets informational_settings.update_available"
  def set_update_available(bot_state_server \\ __MODULE__, bool)
      when is_boolean(bool) do
    GenServer.call(bot_state_server, {:set_update_available, bool})
  end

  @doc "sets informational_settings.node_name"
  def set_node_name(bot_state_server \\ __MODULE__, node_name)
      when is_binary(node_name) do
    GenServer.call(bot_state_server, {:set_node_name, node_name})
  end

  @doc "Fetch the current state."
  def fetch(bot_state_server \\ __MODULE__) do
    GenServer.call(bot_state_server, :fetch)
  end

  def report_disk_usage(bot_state_server \\ __MODULE__, percent) do
    GenServer.call(bot_state_server, {:report_disk_usage, percent})
  end

  def report_memory_usage(bot_state_server \\ __MODULE__, megabytes) do
    GenServer.call(bot_state_server, {:report_memory_usage, megabytes})
  end

  def report_soc_temp(bot_state_server \\ __MODULE__, temp_celcius) do
    GenServer.call(bot_state_server, {:report_soc_temp, temp_celcius})
  end

  def report_uptime(bot_state_server \\ __MODULE__, seconds) do
    GenServer.call(bot_state_server, {:report_uptime, seconds})
  end

  def report_wifi_level(bot_state_server \\ __MODULE__, level) do
    GenServer.call(bot_state_server, {:report_wifi_level, level})
  end

  def report_farmware_installed(bot_state_server \\ __MODULE__, name, %{} = manifest) do
    GenServer.call(bot_state_server, {:report_farmware_installed, name, manifest})
  end

  @doc "Put FBOS into maintenance mode."
  def enter_maintenance_mode(bot_state_server \\ __MODULE__) do
    GenServer.call(bot_state_server, :enter_maintenance_mode)
  end

  @doc false
  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  @doc false
  def init([]) do
    {:ok, %{tree: BotStateNG.new(), subscribers: []}}
  end

  @doc false
  def handle_call(:subscribe, {pid, _} = _from, state) do
    Process.link(pid)
    {:reply, state.tree, %{state | subscribers: Enum.uniq([pid | state.subscribers])}}
  end

  def handle_call(:fetch, _from, state) do
    {:reply, state.tree, state}
  end

  def handle_call({:set_job_progress, name, progress}, _from, state) do
    {reply, state} =
      BotStateNG.set_job_progress(state.tree, name, Map.from_struct(progress))
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:set_enigma, enigma}, _from, state) do
    {reply, state} =
      BotStateNG.set_enigma(state.tree, enigma)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:set_config_value, key, value}, _from, state) do
    change = %{configuration: %{key => value}}

    {reply, state} =
      BotStateNG.changeset(state.tree, change)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:set_user_env, key, value}, _from, state) do
    {reply, state} =
      BotStateNG.set_user_env(state.tree, key, value)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:set_position, x, y, z}, _from, state) do
    change = %{location_data: %{position: %{x: x, y: y, z: z}}}

    {reply, state} =
      BotStateNG.changeset(state.tree, change)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:set_encoders_scaled, x, y, z}, _from, state) do
    change = %{location_data: %{scaled_encoders: %{x: x, y: y, z: z}}}

    {reply, state} =
      BotStateNG.changeset(state.tree, change)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:set_encoders_raw, x, y, z}, _from, state) do
    change = %{location_data: %{raw_encoders: %{x: x, y: y, z: z}}}

    {reply, state} =
      BotStateNG.changeset(state.tree, change)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:set_pin_value, pin, value}, _from, state) do
    {reply, state} =
      BotStateNG.add_or_update_pin(state.tree, pin, -1, value)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:set_firmware_config, param, value}, _from, state) do
    change = %{mcu_params: %{param => value}}

    {reply, state} =
      BotStateNG.changeset(state.tree, change)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:set_firmware_locked, bool}, _from, state) do
    change = %{informational_settings: %{locked: bool}}

    {reply, state} =
      BotStateNG.changeset(state.tree, change)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:set_firmware_version, version}, _from, state) do
    change = %{informational_settings: %{firmware_version: version}}

    {reply, state} =
      BotStateNG.changeset(state.tree, change)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:set_firmware_busy, busy}, _from, state) do
    change = %{informational_settings: %{busy: busy}}

    {reply, state} =
      BotStateNG.changeset(state.tree, change)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:set_sync_status, status}, _from, state) do
    change = %{informational_settings: %{sync_status: status}}

    {reply, state} =
      BotStateNG.changeset(state.tree, change)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:set_update_available, bool}, _from, state) do
    change = %{informational_settings: %{update_available: bool}}

    {reply, state} =
      BotStateNG.changeset(state.tree, change)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:set_node_name, node_name}, _from, state) do
    change = %{informational_settings: %{node_name: node_name}}

    {reply, state} =
      BotStateNG.changeset(state.tree, change)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:report_disk_usage, percent}, _form, state) do
    change = %{informational_settings: %{disk_usage: percent}}

    {reply, state} =
      BotStateNG.changeset(state.tree, change)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:report_memory_usage, megabytes}, _form, state) do
    change = %{informational_settings: %{memory_usage: megabytes}}

    {reply, state} =
      BotStateNG.changeset(state.tree, change)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:report_soc_temp, temp}, _form, state) do
    change = %{informational_settings: %{soc_temp: temp}}

    {reply, state} =
      BotStateNG.changeset(state.tree, change)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:report_uptime, seconds}, _form, state) do
    change = %{informational_settings: %{uptime: seconds}}

    {reply, state} =
      BotStateNG.changeset(state.tree, change)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:report_wifi_level, level}, _form, state) do
    change = %{informational_settings: %{wifi_level: level}}

    {reply, state} =
      BotStateNG.changeset(state.tree, change)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call({:report_farmware_installed, name, manifest}, _from, state) do
    {reply, state} =
      BotStateNG.add_or_update_farmware(state.tree, name, manifest)
        |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  def handle_call(:enter_maintenance_mode, _form, state) do
    change = %{informational_settings: %{sync_status: "maintenance"}}

    {reply, state} =
      BotStateNG.changeset(state.tree, change)
      |> dispatch_and_apply(state)

    {:reply, reply, state}
  end

  defp dispatch_and_apply(%Ecto.Changeset{changes: changes}, state) when map_size(changes) == 0 do
    {:ok, state}
  end

  defp dispatch_and_apply(%Ecto.Changeset{valid?: true} = change, state) do
    state = %{state | tree: Ecto.Changeset.apply_changes(change)}

    state =
      Enum.reduce(state.subscribers, state, fn pid, state ->
        if Process.alive?(pid) do
          send(pid, {__MODULE__, change})
          state
        else
          Process.unlink(pid)
          %{state | subscribers: List.delete(state.subscribers, pid)}
        end
      end)

    {:ok, state}
  end

  defp dispatch_and_apply(%Ecto.Changeset{valid?: false} = change, state) do
    {{:error, change}, state}
  end
end
