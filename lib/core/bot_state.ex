defmodule FarmbotOS.BotState do
  @moduledoc "Central State accumulator."
  alias FarmbotOS.BotStateNG

  require Logger
  require FarmbotOS.Logger
  use GenServer

  FarmbotOS.Logger.report_termination()

  def firmware_offline() do
    FarmbotOS.BotState.set_firmware_version("")
  end

  @doc "Subscribe to BotState changes"
  def subscribe(bot_state_server \\ __MODULE__) do
    GenServer.call(bot_state_server, :subscribe)
  end

  @doc "Set job progress."
  def set_job_progress(bot_state_server \\ __MODULE__, name, progress) do
    GenServer.call(bot_state_server, {:set_job_progress, name, progress})
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

  @doc "Sets the location_data.load"
  def set_load(bot_state_server \\ __MODULE__, x, y, z) do
    GenServer.call(bot_state_server, {:set_load, x, y, z})
  end

  @doc "Sets the location_data.encoders_scaled"
  def set_encoders_scaled(bot_state_server \\ __MODULE__, x, y, z) do
    GenServer.call(bot_state_server, {:set_encoders_scaled, x, y, z})
  end

  @doc "Sets the location_data.encoders_raw"
  def set_encoders_raw(bot_state_server \\ __MODULE__, x, y, z) do
    GenServer.call(bot_state_server, {:set_encoders_raw, x, y, z})
  end

  def set_axis_state(bot_state_server \\ __MODULE__, axis, state) do
    GenServer.call(bot_state_server, {:set_axis_state, axis, state})
  end

  @doc "Sets pins.pin.value"
  def set_pin_value(bot_state_server \\ __MODULE__, pin, value, mode) do
    GenServer.call(bot_state_server, {:set_pin_value, pin, value, mode})
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

  @doc "Sets configuration.arduino_hardware"
  def set_firmware_hardware(bot_state_server \\ __MODULE__, hardware) do
    GenServer.call(bot_state_server, {:set_firmware_hardware, hardware})
  end

  @doc "Sets informational_settings.busy"
  def set_firmware_busy(bot_state_server \\ __MODULE__, busy) do
    GenServer.call(bot_state_server, {:set_firmware_busy, busy})
  end

  @doc "Sets informational_settings.idle"
  def set_firmware_idle(bot_state_server \\ __MODULE__, idle) do
    GenServer.call(bot_state_server, {:set_firmware_idle, idle})
  end

  @doc "Sets informational_settings.status"
  def set_sync_status(bot_state_server \\ __MODULE__, s)
      when s in ["sync_now", "syncing", "synced", "sync_error", "maintenance"] do
    GenServer.call(bot_state_server, {:set_sync_status, s})
  end

  @doc "sets informational_settings.node_name"
  def set_node_name(bot_state_server \\ __MODULE__, node_name)
      when is_binary(node_name) do
    GenServer.call(bot_state_server, {:set_node_name, node_name})
  end

  @doc "sets informational_settings.private_ip"
  def set_private_ip(bot_state_server \\ __MODULE__, private_ip) do
    GenServer.call(bot_state_server, {:set_private_ip, private_ip})
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

  def report_scheduler_usage(bot_state_server \\ __MODULE__, percent) do
    GenServer.call(bot_state_server, {:report_scheduler_usage, percent})
  end

  def report_soc_temp(bot_state_server \\ __MODULE__, temp_celsius) do
    GenServer.call(bot_state_server, {:report_soc_temp, temp_celsius})
  end

  def report_throttled(bot_state_server \\ __MODULE__, throttled_str) do
    GenServer.call(bot_state_server, {:report_throttled, throttled_str})
  end

  def report_uptime(bot_state_server \\ __MODULE__, seconds) do
    GenServer.call(bot_state_server, {:report_uptime, seconds})
  end

  def report_wifi_level(bot_state_server \\ __MODULE__, level) do
    GenServer.call(bot_state_server, {:report_wifi_level, level})
  end

  def report_wifi_level_percent(bot_state_server \\ __MODULE__, percent) do
    GenServer.call(bot_state_server, {:report_wifi_level_percent, percent})
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
    # TODO Just replace this with Elixir.Registry?
    # Process.link(pid)
    {:reply, state.tree,
     %{state | subscribers: Enum.uniq([pid | state.subscribers])}}
  end

  def handle_call(:fetch, _from, state) do
    {:reply, state.tree, state}
  end

  def handle_call({:set_job_progress, name, progress}, _from, state) do
    {reply, state} =
      BotStateNG.set_job_progress(state.tree, name, Map.from_struct(progress))
      |> dispatch_and_apply(state)

    {:reply, reply, remove_old_jobs(state)}
  end

  def handle_call({:set_config_value, key, value}, _from, state) do
    change = %{configuration: %{key => value}}

    {reply, state} = get_reply_from_change(state, change)
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

    {reply, state} = get_reply_from_change(state, change)
    {:reply, reply, state}
  end

  def handle_call({:set_load, x, y, z}, _from, state) do
    change = %{location_data: %{load: %{x: x, y: y, z: z}}}

    {reply, state} = get_reply_from_change(state, change)
    {:reply, reply, state}
  end

  def handle_call({:set_encoders_scaled, x, y, z}, _from, state) do
    change = %{location_data: %{scaled_encoders: %{x: x, y: y, z: z}}}

    {reply, state} = get_reply_from_change(state, change)
    {:reply, reply, state}
  end

  def handle_call({:set_encoders_raw, x, y, z}, _from, state) do
    change = %{location_data: %{raw_encoders: %{x: x, y: y, z: z}}}

    {reply, state} = get_reply_from_change(state, change)
    {:reply, reply, state}
  end

  def handle_call({:set_axis_state, axis, axis_state}, _from, state) do
    change = %{
      location_data: %{
        axis_states: %{
          axis => to_string(axis_state)
        }
      }
    }

    {reply, state} = get_reply_from_change(state, change)
    {:reply, reply, state}
  end

  def handle_call({:set_pin_value, pin, val, mode}, _from, state1) do
    # Under some circumstances, `m` (mode) will be nil.
    # We must guess
    {reply, state2} =
      BotStateNG.add_or_update_pin(state1.tree, pin, mode || -1, val)
      |> dispatch_and_apply(state1)

    {:reply, reply, state2}
  end

  def handle_call({:set_firmware_config, param, value}, _from, state) do
    change = %{mcu_params: %{param => value}}

    {reply, state} = get_reply_from_change(state, change)
    {:reply, reply, state}
  end

  def handle_call({:set_firmware_locked, bool}, _from, state) do
    update =
      if bool do
        t = FarmbotOS.Time.system_time_ms()
        %{locked: bool, locked_at: t}
      else
        %{locked: bool}
      end

    change = %{informational_settings: update}

    {reply, state} = get_reply_from_change(state, change)
    {:reply, reply, state}
  end

  def handle_call({:set_firmware_version, version}, _from, state) do
    change = %{informational_settings: %{firmware_version: version}}

    {reply, state} = get_reply_from_change(state, change)
    {:reply, reply, state}
  end

  def handle_call({:set_firmware_hardware, hardware}, _from, state) do
    change = %{configuration: %{firmware_hardware: hardware}}

    {reply, state} = get_reply_from_change(state, change)
    {:reply, reply, state}
  end

  def handle_call({:set_firmware_busy, busy}, _from, state) do
    change = %{informational_settings: %{busy: busy}}

    {reply, state} = get_reply_from_change(state, change)
    {:reply, reply, state}
  end

  def handle_call({:set_firmware_idle, idle}, _from, state) do
    change = %{informational_settings: %{idle: idle}}

    {reply, state} = get_reply_from_change(state, change)
    {:reply, reply, state}
  end

  def handle_call({:set_sync_status, status}, _from, state) do
    change = %{informational_settings: %{sync_status: status}}

    {reply, state} = get_reply_from_change(state, change)
    {:reply, reply, state}
  end

  def handle_call({:set_node_name, node_name}, _from, state) do
    change = %{informational_settings: %{node_name: node_name}}

    {reply, state} = get_reply_from_change(state, change)
    {:reply, reply, state}
  end

  def handle_call({:set_private_ip, private_ip}, _from, state) do
    change = %{informational_settings: %{private_ip: private_ip}}

    {reply, state} = get_reply_from_change(state, change)
    {:reply, reply, state}
  end

  def handle_call({:report_disk_usage, percent}, _form, state) do
    change = %{informational_settings: %{disk_usage: percent}}

    {reply, state} = get_reply_from_change(state, change)
    {:reply, reply, state}
  end

  def handle_call({:report_memory_usage, megabytes}, _form, state) do
    change = %{informational_settings: %{memory_usage: megabytes}}

    {reply, state} = get_reply_from_change(state, change)
    {:reply, reply, state}
  end

  def handle_call({:report_scheduler_usage, average_percent}, _form, state) do
    change = %{informational_settings: %{scheduler_usage: average_percent}}

    {reply, state} = get_reply_from_change(state, change)
    {:reply, reply, state}
  end

  def handle_call({:report_soc_temp, temp}, _form, state) do
    change = %{informational_settings: %{soc_temp: temp}}

    {reply, state} = get_reply_from_change(state, change)
    {:reply, reply, state}
  end

  def handle_call({:report_throttled, throttled_str}, _form, state) do
    change = %{informational_settings: %{throttled: throttled_str}}

    {reply, state} = get_reply_from_change(state, change)
    {:reply, reply, state}
  end

  def handle_call({:report_uptime, seconds}, _form, state) do
    FarmbotOS.SysCalls.CheckUpdate.uptime_hotfix(seconds)
    change = %{informational_settings: %{uptime: seconds}}

    {reply, state} = get_reply_from_change(state, change)
    {:reply, reply, state}
  end

  def handle_call({:report_wifi_level, level}, _form, state) do
    change = %{informational_settings: %{wifi_level: level}}

    {reply, state} = get_reply_from_change(state, change)
    {:reply, reply, state}
  end

  def handle_call({:report_wifi_level_percent, percent}, _form, state) do
    change = %{informational_settings: %{wifi_level_percent: percent}}

    {reply, state} = get_reply_from_change(state, change)
    {:reply, reply, state}
  end

  defp dispatch_and_apply(%Ecto.Changeset{changes: changes}, state)
       when map_size(changes) == 0 do
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

  defp get_reply_from_change(state, change) do
    dispatch_and_apply(BotStateNG.changeset(state.tree, change), state)
  end

  # Remove jobs that haven't been updated in > 5 minutes.
  # This prevents system crashes when users take extremely
  # large numbers of photos.
  defp remove_old_jobs(state) do
    now = round(FarmbotOS.Time.system_time_ms() / 1000)
    reject = fn {_name, job} -> now - job.updated_at > 300 end
    recombine = fn {name, job}, acc -> Map.put(acc, name, job) end

    next_jobs =
      state.tree.jobs
      |> Map.to_list()
      |> Enum.reject(reject)
      |> Enum.reduce(%{}, recombine)

    %{state | tree: %{state.tree | jobs: next_jobs}}
  end
end
