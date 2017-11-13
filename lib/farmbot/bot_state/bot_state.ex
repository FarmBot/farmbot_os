defmodule Farmbot.BotState do
  @moduledoc "JSON Serializable state tree that gets pushed over variour transports."

  use GenStage
  @version Mix.Project.config()[:version]
  @commit Mix.Project.config()[:commit]
  @target Mix.Project.config()[:target]
  @env Mix.env()

  alias Farmbot.CeleryScript.AST
  use Farmbot.Logger

  defstruct mcu_params: %{
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
      pin_guard_5_active_state: nil,
    },
            jobs: %{},
            location_data: %{
              position: %{x: -1, y: -1, z: -1}
            },
            pins: %{},
            configuration: %{},
            informational_settings: %{
              controller_version: @version,
              commit: @commit,
              target: @target,
              env: @env,
              busy: false,
              sync_status: :sync_now,
            },
            user_env: %{},
            process_info: %{
              farmwares: %{}
            }

    def download_progress_fun(name) do
    alias Farmbot.BotState.JobProgress
    fn(bytes, total) ->
      {do_send, prog} = cond do
        # if the total is complete spit out the bytes, and put a status of complete.
        total == :complete ->
          Logger.success 3, "#{name} complete."
          {true, %JobProgress.Bytes{bytes: bytes, status: :complete}}

        # if we don't know the total just spit out the bytes.
        total == nil ->
          # debug_log "#{name} - #{bytes} bytes."
          {rem(bytes, 10) == 0, %JobProgress.Bytes{bytes: bytes}}
        # if the number of bytes == the total bytes, percentage side is complete.
        (div(bytes,total)) == 1 ->
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

  @doc "Set job progress."
  def set_job_progress(name, progress) do
    GenServer.call(__MODULE__, {:set_job_progress, name, progress})
  end

  @doc "Get a current pin value."
  def get_pin_value(num) do
    GenStage.call(__MODULE__, {:get_pin_value, num})
  end

  def get_current_pos do
    GenStage.call(__MODULE__, :get_current_pos)
  end

  @doc false
  def set_busy(bool) do
    GenStage.call(__MODULE__, {:set_busy, bool})
  end

  @valid_sync_status [:locked, :maintenance, :sync_error, :sync_now, :synced, :syncing, :unknown]
  @doc "Set the sync status above ticker to a message."
  def set_sync_status(cmd) when cmd in @valid_sync_status do
    GenStage.call(__MODULE__, {:set_sync_status, cmd})
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
    {
      :producer_consumer,
      struct(__MODULE__, configuration: Farmbot.System.ConfigStorage.get_config_as_map()["settings"]),
      subscribe_to: [Farmbot.Firmware, Farmbot.System.ConfigStorage.Dispatcher],
      dispatcher: GenStage.BroadcastDispatcher
    }
  end

  def handle_events(events, _from, state) do
    # Logger.busy 3, "begin handle bot state events"
    state = do_handle(events, state)
    # Logger.success 3, "Finish handle bot state events"
    {:noreply, [state], state}
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
    {:reply, state, [state], state}
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
    new_info_settings = %{state.informational_settings | sync_status: status}
    new_state = %{state | informational_settings: new_info_settings}
    {:reply, :ok, [new_state], new_state}
  end

  def handle_call({:set_user_env, key, val}, _, state) do
    new_user_env = Map.put(state.user_env, key, val)
    new_state = %{state | user_env: new_user_env}
    {:reply, :ok, [new_state], new_state}
  end

  def handle_call(:get_user_env, _from, state) do
    {:reply, state.user_env, [], state}
  end

  def handle_call(:get_current_pos, _from, state) do
    {:reply, state.location_data.position, [], state}
  end

  def handle_call({:set_job_progress, name, progress}, _from, state) do
    jobs = Map.put(state.jobs, name, progress)
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

  defp do_handle([{:config, "settings", key, val} | rest], state) do
    new_config = Map.put(state.configuration, key, val)
    new_state = %{state | configuration: new_config}
    do_handle(rest, new_state)
  end

  defp do_handle([{:config, _, _, _} | rest], state) do
    do_handle(rest, state)
  end

  defp do_handle([{key, diff} | rest], state) do
    state = %{state | key => Map.merge(Map.get(state, key), diff)}
    do_handle(rest, state)
  end
end
