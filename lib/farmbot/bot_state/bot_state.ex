defmodule Farmbot.BotState do
  @moduledoc """
  Central bot state that gets pushed out over transports.
    * JSON Serializable
    * Global
    * Scary
  """

  use GenStage
  @version Farmbot.Project.version()
  @commit Farmbot.Project.commit()
  @arduino_commit Farmbot.Project.arduino_commit()
  @target Farmbot.Project.target()
  @env Farmbot.Project.env()

  alias Farmbot.CeleryScript.AST
  alias Farmbot.System.ConfigStorage
  import ConfigStorage, only: [update_config_value: 4]
  alias Farmbot.Firmware
  use Farmbot.Logger

  def download_progress_fun(name) do
    alias Farmbot.BotState.JobProgress
    fn(bytes, total) ->
      {do_send, prog} = cond do
        # if the total is complete spit out the bytes,
        # and put a status of complete.
        total == :complete ->
          Logger.success 3, "#{name} complete."
          {true, %JobProgress.Bytes{bytes: bytes, status: :complete}}

        # if we don't know the total just spit out the bytes.
        total == nil ->
          # debug_log "#{name} - #{bytes} bytes."
          {rem(bytes, 10) == 0, %JobProgress.Bytes{bytes: bytes}}
        # if the number of bytes == the total bytes,
        # percentage side is complete.
        (div(bytes, total)) == 1 ->
          Logger.success 3, "#{name} complete."
          {true, %JobProgress.Percent{percent: 100, status: :complete}}
        # anything else is a percent.
        true ->
          percent = ((bytes / total) * 100) |> round()
          # Logger.busy 3, "#{name} - #{bytes}/#{total} = #{percent}%"
          {rem(percent, 10) == 0, %JobProgress.Percent{percent: percent}}
      end
      if do_send do
        Farmbot.BotState.set_job_progress(name, prog)
      else
        :ok
      end
    end
  end

  def report_soc_temp(temp_celcius) when is_number(temp_celcius) do
    GenStage.call(__MODULE__, {:report_soc_temp, temp_celcius})
  end

  def locked? do
    GenStage.call(__MODULE__, :locked?)
  end

  @doc "Set job progress."
  def set_job_progress(name, progress) do
    GenServer.call(__MODULE__, {:set_job_progress, name, progress})
  end

  def clear_progress_fun(name) do
    GenServer.call(__MODULE__, {:clear_progress_fun, name})
  end

  @doc "Get a current pin value."
  def get_pin_value(num) do
    GenStage.call(__MODULE__, {:get_pin_value, num})
  end

  @doc "Get the bot's current position."
  def get_current_pos do
    GenStage.call(__MODULE__, :get_current_pos)
  end

  @doc "Get a arduino param."
  def get_param(param) do
    GenStage.call(__MODULE__, {:get_param, param})
  end

  @doc false
  def set_busy(bool) do
    GenStage.call(__MODULE__, {:set_busy, bool})
  end

  @valid_sync_status [
    :maintenance,
    :sync_error,
    :sync_now,
    :synced,
    :syncing,
    :unknown
  ]

  @doc "Set the sync status above ticker to a message."
  def set_sync_status(cmd) when cmd in @valid_sync_status do
    # {:current_stacktrace, stacktrace} = Process.info(self(), :current_stacktrace)
    # caller = Enum.at(stacktrace, 2)
    # Logger.debug 3, "Sync status changing to `#{cmd}`: #{inspect caller}"
    GenStage.call(__MODULE__, {:set_sync_status, cmd})
  end

  @doc "Set the sync status to the previous status."
  def reset_sync_status do
    GenStage.call(__MODULE__, :reset_sync_status)
  end

  @doc "Forces a state push over all transports."
  def force_state_push do
    GenStage.call(__MODULE__, :force_state_push)
  end

  @doc "Register a farmware in the bot's state."
  def register_farmware(%Farmbot.Farmware{} = fw) do
    GenStage.call(__MODULE__, {:register_farmware, fw})
  end

  @doc "Unregister a farmware form the bot's state."
  def unregister_farmware(%Farmbot.Farmware{} = fw) do
    GenStage.call(__MODULE__, {:unregister_farmware, fw})
  end

  @doc "Emit an AST."
  def emit(%AST{} = ast) do
    GenStage.call(__MODULE__, {:emit, ast})
  end

  @doc "Get user env."
  def get_user_env do
    GenStage.call(__MODULE__, :get_user_env)
  end

  @doc "Set user env."
  def set_user_env(key, val) do
    GenStage.call(__MODULE__, {:set_user_env, key, val})
  end

  @doc false
  def start_link() do
    GenStage.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    settings = ConfigStorage.get_config_as_map()["settings"]
    user_env = Poison.decode!(settings["user_env"])
    state_opts = [
      configuration: Map.delete(settings, "user_env"),
      user_env: user_env
    ]
    initial_state = struct(__MODULE__, state_opts)
    info_settings = %{initial_state.informational_settings | node_name: node()}
    state = %{initial_state | informational_settings: info_settings}
    gen_stage_opts = [
      subscribe_to: [Firmware, ConfigStorage.Dispatcher, Farmbot.System.GPIO],
      dispatcher: GenStage.BroadcastDispatcher
    ]
    {:producer_consumer, state, gen_stage_opts}
  end

  def handle_events(events, _from, state) do
    state = do_handle(events, state)
    # Logger.success 3, "Finish handle bot state events"
    {:noreply, [state], state}
  end

  def handle_call({:report_soc_temp, temp}, _from, state) do
    new_info_settings = %{state.informational_settings | soc_temp: temp}
    {:reply, :ok, %{state | informational_settings: new_info_settings}}
  end

  def handle_call(:locked?, _from, state) do
    {:reply, state.informational_settings.locked, [], state}
  end

  def handle_call({:get_pin_value, pin}, _from, state) do
    case state.pins[pin] do
      nil ->
        {:reply, {:error, :unknown_pin}, [], state}
      %{value: value} ->
        {:reply, {:ok, value}, [], state}
    end
  end

  def handle_call(:force_state_push, _from, state) do
    new_state = update_in(state, [:informational_settings, :cache_bust], fn(old) ->
      old + 1
    end)
    {:reply, new_state, [new_state], new_state}
  end

  def handle_call({:set_busy, bool}, _from, state) do
    new_info_settings = %{state.informational_settings | busy: bool}
    new_state = %{state | informational_settings: new_info_settings}
    {:reply, :ok, [new_state], new_state}
  end

  def handle_call({:emit, ast}, _from, state) do
    {:reply, :ok, [{:emit, ast}], state}
  end

  def handle_call({:set_sync_status, status}, _, state) do
    last = state.informational_settings.sync_status
    new_info_settings = %{state.informational_settings | sync_status: status, last_status: last}
    new_state = %{state | informational_settings: new_info_settings}
    {:reply, :ok, [new_state], new_state}
  end

  def handle_call(:reset_sync_status, _, state) do
    current = state.informational_settings.sync_status
    last = state.informational_settings.last_status
    new_info_settings = %{state.informational_settings | sync_status: last, last_status: current}
    new_state = %{state | informational_settings: new_info_settings}
    {:reply, :ok, [new_state], new_state}
  end

  def handle_call({:set_user_env, key, val}, _, state) do
    new_user_env = Map.merge(state.user_env, %{to_string(key) => val})
    case Poison.encode(new_user_env) do
      {:ok, encoded} ->
        update_config_value(:string, "settings", "user_env", encoded)
        {:reply, :ok, [], state}
      _ -> {:reply, {:error, "user_env must be json encodeable!"}, [], state}
    end
  end

  def handle_call(:get_user_env, _from, state) do
    {:reply, state.user_env, [], state}
  end

  def handle_call(:get_current_pos, _from, state) do
    {:reply, state.location_data.position, [], state}
  end

  def handle_call({:get_param, param}, _from, state) do
    {:reply, state.mcu_params[param], [], state}
  end

  def handle_call({:set_job_progress, name, progress}, _from, state) do
    jobs = Map.put(state.jobs, name, progress)
    new_state = %{state | jobs: jobs}
    {:reply, :ok, [new_state], new_state}
  end

  def handle_call({:clear_progress_fun, name}, _from, state) do
    jobs = Map.delete(state.jobs, name)
    new_state = %{state | jobs: jobs}
    {:reply, :ok, [new_state], new_state}
  end

  def handle_call({:register_farmware, fw}, _, state) do
    ser_fw_meta = %{
      min_os_version_major: fw.min_os_version_major,
      description: fw.meta.description,
      language: fw.meta.language,
      version: to_string(fw.version),
      author: fw.meta.author,
      zip: fw.zip
    }
    ser_fw = %{
      args: fw.args,
      executable: fw.executable,
      meta: ser_fw_meta,
      name: fw.name,
      path: Farmbot.Farmware.Installer.install_path(fw),
      config: fw.config,
      url: fw.url
    }
    new_pi = Map.put(state.process_info.farmwares, fw.name, ser_fw)
    new_state = %{state | process_info: %{farmwares: new_pi}}
    {:reply, :ok, [new_state], new_state}
  end

  def handle_call({:unregister_farmware, fw}, _, state) do
    new_pi = Map.delete(state.process_info.farmwares, fw.name)
    new_state = %{state | process_info: %{farmwares: new_pi}}
    {:reply, :ok, [new_state], new_state}
  end

  defp do_handle([], state), do: state

  defp do_handle(data, %{informational_settings: %{sync_status: :booting}} = state) do
    do_handle(data, %{state | informational_settings: %{state.informational_settings | sync_status: :sync_now}})
  end
  # User env is json and kind of a mess.
  defp do_handle([{:config, "settings", "user_env", val} | rest], state) do
    new_env = Map.merge(state.user_env, Poison.decode!(val))
    new_state = %{state | user_env: new_env}
    do_handle(rest, new_state)
  end

  # TODO(Connor) - this should probably be moved to the system config registry.
  defp do_handle([{:config, "settings", "auto_sync", true} | rest], state) do
    # Toggling autosync should force a sync.
    spawn Farmbot.Repo, :sync, []
    new_config = Map.put(state.configuration, "auto_sync", true)
    new_state = %{state | configuration: new_config}
    do_handle(rest, new_state)
  end

  defp do_handle([{:config, "settings", key, val} | rest], state) do
    # Logger.debug 1, "Got config update: #{inspect key} => #{inspect val}"
    new_config = Map.put(state.configuration, key, val)
    new_state = %{state | configuration: new_config}
    do_handle(rest, new_state)
  end

  defp do_handle([{:config, _, _, _} | rest], state) do
    do_handle(rest, state)
  end

  # This one is special because it sends the _entire_ sub tree, not just
  # Parts of it.
  defp do_handle([{:gpio_registry, gpio_registry} | rest], state) do
    do_handle(rest, %{state | gpio_registry: gpio_registry})
  end

  defp do_handle([{key, diff} | rest], state) do
    state = %{state | key => Map.merge(Map.get(state, key), diff)}
    do_handle(rest, state)
  end

  defstruct [
    informational_settings: %{
      controller_version: @version,
      firmware_version: "disconnected",
      firmware_commit: @arduino_commit,
      commit: @commit,
      target: @target,
      env: @env,
      node_name: nil,
      busy: false,
      sync_status: :booting,
      last_status: nil,
      locked: false,
      cache_bust: 0,
      soc_temp: 0,
    },
    location_data: %{
      position: %{x: nil, y: nil, z: nil},
      scaled_encoders: %{x: nil, y: nil, z: nil},
      raw_encoders: %{x: nil, y: nil, z: nil},
    },
    process_info: %{
      farmwares: %{}
    },
    mcu_params: %{
      param_version: nil,
      param_test: nil,
      param_config_ok: nil,
      param_use_eeprom: nil,
      param_e_stop_on_mov_err: nil,
      param_mov_nr_retry: nil,
      movement_timeout_x: nil,
      movement_timeout_y: nil,
      movement_timeout_z: nil,
      movement_keep_active_x: nil,
      movement_keep_active_y: nil,
      movement_keep_active_z: nil,
      movement_home_at_boot_x: nil,
      movement_home_at_boot_y: nil,
      movement_home_at_boot_z: nil,
      movement_invert_endpoints_x: nil,
      movement_invert_endpoints_y: nil,
      movement_invert_endpoints_z: nil,
      movement_enable_endpoints_x: nil,
      movement_enable_endpoints_y: nil,
      movement_enable_endpoints_z: nil,
      movement_invert_motor_x: nil,
      movement_invert_motor_y: nil,
      movement_invert_motor_z: nil,
      movement_secondary_motor_x: nil,
      movement_secondary_motor_invert_x: nil,
      movement_steps_acc_dec_x: nil,
      movement_steps_acc_dec_y: nil,
      movement_steps_acc_dec_z: nil,
      movement_stop_at_home_x: nil,
      movement_stop_at_home_y: nil,
      movement_stop_at_home_z: nil,
      movement_home_up_x: nil,
      movement_home_up_y: nil,
      movement_home_up_z: nil,
      movement_step_per_mm_x: nil,
      movement_step_per_mm_y: nil,
      movement_step_per_mm_z: nil,
      movement_min_spd_x: nil,
      movement_min_spd_y: nil,
      movement_min_spd_z: nil,
      movement_home_spd_x: nil,
      movement_home_spd_y: nil,
      movement_home_spd_z: nil,
      movement_max_spd_x: nil,
      movement_max_spd_y: nil,
      movement_max_spd_z: nil,
      movement_invert_2_endpoints_x: nil,
      movement_invert_2_endpoints_y: nil,
      movement_invert_2_endpoints_z: nil,
      encoder_enabled_x: nil,
      encoder_enabled_y: nil,
      encoder_enabled_z: nil,
      encoder_type_x: nil,
      encoder_type_y: nil,
      encoder_type_z: nil,
      encoder_missed_steps_max_x: nil,
      encoder_missed_steps_max_y: nil,
      encoder_missed_steps_max_z: nil,
      encoder_scaling_x: nil,
      encoder_scaling_y: nil,
      encoder_scaling_z: nil,
      encoder_missed_steps_decay_x: nil,
      encoder_missed_steps_decay_y: nil,
      encoder_missed_steps_decay_z: nil,
      encoder_use_for_pos_x: nil,
      encoder_use_for_pos_y: nil,
      encoder_use_for_pos_z: nil,
      encoder_invert_x: nil,
      encoder_invert_y: nil,
      encoder_invert_z: nil,
      movement_axis_nr_steps_x: nil,
      movement_axis_nr_steps_y: nil,
      movement_axis_nr_steps_z: nil,
      movement_stop_at_max_x: nil,
      movement_stop_at_max_y: nil,
      movement_stop_at_max_z: nil,
      pin_guard_1_pin_nr: nil,
      pin_guard_1_time_out: nil,
      pin_guard_1_active_state: nil,
      pin_guard_2_pin_nr: nil,
      pin_guard_2_time_out: nil,
      pin_guard_2_active_state: nil,
      pin_guard_3_pin_nr: nil,
      pin_guard_3_time_out: nil,
      pin_guard_3_active_state: nil,
      pin_guard_4_pin_nr: nil,
      pin_guard_4_time_out: nil,
      pin_guard_4_active_state: nil,
      pin_guard_5_pin_nr: nil,
      pin_guard_5_time_out: nil,
      pin_guard_5_active_state: nil
    },
    jobs: %{},
    gpio_registry: %{},
    pins: %{},
    configuration: %{},
    user_env: %{}
  ]

  @behaviour Access
  def fetch(state, key), do: Map.fetch(state, key)
  def get(state, key, default), do: Map.get(state, key, default)
  def get_and_update(state, key, fun), do: Map.get_and_update(state, key, fun)
  def pop(state, key), do: Map.pop(state, key)
end
