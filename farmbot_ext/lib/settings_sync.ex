defmodule Farmbot.SettingsSync do
  @moduledoc "Handles uploading and downloading of Farmbot OS and Firmware configs."
  require Farmbot.Logger
  import Farmbot.Config,
    only: [get_config_value: 3, update_config_value: 4, get_config_as_map: 0]

  @fbos_keys [
    "auto_sync",
    "beta_opt_in",
    "disable_factory_reset",
    "firmware_output_log",
    "firmware_input_log",
    "sequence_body_log",
    "sequence_complete_log",
    "sequence_init_log",
    "arduino_debug_messages",
    "os_auto_update",
    "firmware_hardware",
    "network_not_found_timer"
  ]

  @firmware_keys [
    "param_version",
    "param_test",
    "param_config_ok",
    "param_use_eeprom",
    "param_e_stop_on_mov_err",
    "param_mov_nr_retry",
    "movement_timeout_x",
    "movement_timeout_y",
    "movement_timeout_z",
    "movement_keep_active_x",
    "movement_keep_active_y",
    "movement_keep_active_z",
    "movement_home_at_boot_x",
    "movement_home_at_boot_y",
    "movement_home_at_boot_z",
    "movement_invert_endpoints_x",
    "movement_invert_endpoints_y",
    "movement_invert_endpoints_z",
    "movement_enable_endpoints_x",
    "movement_enable_endpoints_y",
    "movement_enable_endpoints_z",
    "movement_invert_motor_x",
    "movement_invert_motor_y",
    "movement_invert_motor_z",
    "movement_secondary_motor_x",
    "movement_secondary_motor_invert_x",
    "movement_steps_acc_dec_x",
    "movement_steps_acc_dec_y",
    "movement_steps_acc_dec_z",
    "movement_stop_at_home_x",
    "movement_stop_at_home_y",
    "movement_stop_at_home_z",
    "movement_home_up_x",
    "movement_home_up_y",
    "movement_home_up_z",
    "movement_step_per_mm_x",
    "movement_step_per_mm_y",
    "movement_step_per_mm_z",
    "movement_min_spd_x",
    "movement_min_spd_y",
    "movement_min_spd_z",
    "movement_home_spd_x",
    "movement_home_spd_y",
    "movement_home_spd_z",
    "movement_max_spd_x",
    "movement_max_spd_y",
    "movement_max_spd_z",
    "movement_invert_2_endpoints_x",
    "movement_invert_2_endpoints_y",
    "movement_invert_2_endpoints_z",
    "encoder_enabled_x",
    "encoder_enabled_y",
    "encoder_enabled_z",
    "encoder_type_x",
    "encoder_type_y",
    "encoder_type_z",
    "encoder_missed_steps_max_x",
    "encoder_missed_steps_max_y",
    "encoder_missed_steps_max_z",
    "encoder_scaling_x",
    "encoder_scaling_y",
    "encoder_scaling_z",
    "encoder_missed_steps_decay_x",
    "encoder_missed_steps_decay_y",
    "encoder_missed_steps_decay_z",
    "encoder_use_for_pos_x",
    "encoder_use_for_pos_y",
    "encoder_use_for_pos_z",
    "encoder_invert_x",
    "encoder_invert_y",
    "encoder_invert_z",
    "movement_axis_nr_steps_x",
    "movement_axis_nr_steps_y",
    "movement_axis_nr_steps_z",
    "movement_stop_at_max_x",
    "movement_stop_at_max_y",
    "movement_stop_at_max_z",
    "pin_guard_1_pin_nr",
    "pin_guard_1_time_out",
    "pin_guard_1_active_state",
    "pin_guard_2_pin_nr",
    "pin_guard_2_time_out",
    "pin_guard_2_active_state",
    "pin_guard_3_pin_nr",
    "pin_guard_3_time_out",
    "pin_guard_3_active_state",
    "pin_guard_4_pin_nr",
    "pin_guard_4_time_out",
    "pin_guard_4_active_state",
    "pin_guard_5_pin_nr",
    "pin_guard_5_time_out",
    "pin_guard_5_active_state",
  ]

  # TODO: This should be moved to ConfigStorage module maybe?
  @bool_keys [
    "auto_sync",
    "beta_opt_in",
    "disable_factory_reset",
    "firmware_output_log",
    "firmware_input_log",
    "sequence_body_log",
    "sequence_complete_log",
    "sequence_init_log",
    "arduino_debug_messages",
    "os_auto_update"
  ]

  @string_keys [
    "firmware_hardware"
  ]

  @float_keys @firmware_keys ++ [
    "network_not_found_timer"
  ]

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end


  @doc false
  def start_link(_) do
    run()
    :ignore
  end

  @doc false
  def run() do
    try do
      do_sync_fw_configs()
      do_sync_fbos_configs()
      Farmbot.Logger.debug 1, "Synced Farmbot OS and Firmware settings with API"
      :ok
    rescue
      err ->
        message = Exception.message(err)
        err_msg = "#{message} #{inspect System.stacktrace()}"
        Farmbot.Logger.error 1, "Error syncing settings: #{err_msg}"
        update_config_value(:bool, "settings", "ignore_fbos_config", false)
        update_config_value(:bool, "settings", "ignore_fw_config", false)
        {:error, message}
    end
  end

  def apply_fbos_map(old_map, new_map) do
    old_map = take_valid_fbos(old_map)
    new_map = take_valid_fbos(new_map)
    Map.new(new_map, fn({key, new_value}) ->
      if old_map[key] !== new_value do
        Farmbot.Logger.debug 3, "Got new config update: #{key} => #{new_value}"
        apply_to_config_storage key, new_value
      end
      {key, new_value}
    end)
  end

  def apply_fw_map(old_map, new_map) do
    old_map = take_valid_fw(old_map)
    new_map = take_valid_fw(new_map)
    new_stuff = Map.new(new_map, fn({key, new_value}) ->
      if old_map[key] != new_value do
        IO.puts "1 #{key} #{old_map[key]} != #{new_value}"
        apply_to_config_storage key, new_value
        {key, new_value}
      else
        {key, old_map[key]}
      end
    end)

    if Process.whereis(Farmbot.Firmware) do
      Map.new(new_map, fn({param, new_value}) ->
        if old_map[param] != new_value do
          IO.puts "2 #{param} #{old_map[param]} != #{new_value}"
          Farmbot.Firmware.update_param(String.to_atom(param), new_value)
          Farmbot.Firmware.read_param(String.to_atom(param))
        end
        {param, get_config_value(:float, "hardware_params", param)}
      end)
    else
      new_stuff
    end
  end

  defp apply_to_config_storage(key, val)
  when key in @bool_keys and (is_nil(val) or is_boolean(val)) do
    Farmbot.Logger.success 2, "Updating: #{key} => #{inspect val}"
    update_config_value(:bool, "settings", key, val)
  end

  defp apply_to_config_storage(key, val)
  when key in @string_keys and (is_nil(val) or is_binary(val)) do
    Farmbot.Logger.success 2, "Updating: #{key} => #{inspect val}"
    update_config_value(:string, "settings", key, val)
  end

  defp apply_to_config_storage(key, val)
  when key in @firmware_keys do
    if val do
      Farmbot.Logger.success 2, "Updating FW param: #{key}: #{get_config_value(:float, "hardware_params", key)} => #{val}"
      update_config_value(:float, "hardware_params", key, val / 1)
    else
      Farmbot.Logger.warn 2, "Not allowing #{key} to be set to null"
    end
  end

  defp apply_to_config_storage(key, val)
  when key in @float_keys and (is_nil(val) or is_number(val)) do
    Farmbot.Logger.success 2, "Updating: #{key} => #{inspect val}"
    if val do
      update_config_value(:float, "settings", key, val / 1)
    else
      update_config_value(:float, "settings", key, val)
    end
  end

  defp apply_to_config_storage(key, val) do
    Farmbot.Logger.error 1, "Unknown pair: #{key} => #{inspect val}"
    {:error, {:unknown_pair, {key, val}}}
  end

  @doc "Sync the settings related to the Firmware."
  def do_sync_fw_configs do
    with {:ok, %{body: body, status_code: 200}} <- Farmbot.HTTP.get("/api/firmware_config"),
    {:ok, data} <- Farmbot.JSON.decode(body)
    do
      do_sync_fw_configs(data)
    else
      {:ok, status_code: code} ->
        Farmbot.Logger.error 1, "HTTP error syncing settings: #{code}"
        :ok
      err ->
        Farmbot.Logger.error 1, "Error syncing settings: #{inspect err}"
        :ok
    end
  end

  def do_sync_fw_configs(api_data) do
    update_config_value(:bool, "settings", "ignore_fw_config", true)
      Farmbot.Logger.info 3, "API is source of truth for fw configs."
      current = get_config_as_map()["hardware_params"]
      apply_fw_map(current, api_data)
    update_config_value(:bool, "settings", "ignore_fw_config", false)
    :ok
  end

  @doc "Uploads a single key value pair to the firmware config endpoint."
  def upload_fw_kv(key, val) when is_binary(key) and key in @firmware_keys and is_number(val)
  do
    Farmbot.Logger.debug 3, "Uploading #{key} => #{val} to api."
    payload = Farmbot.JSON.encode!(%{key => val})
    %{status_code: 200} = Farmbot.HTTP.put!("/api/firmware_config", payload)
    :ok
  end

  @doc "Sync the settings related to Farmbot OS and Firmware"
  def do_sync_fbos_configs do
    with {:ok, %{body: body, status_code: 200}} <- Farmbot.HTTP.get("/api/fbos_config"),
    {:ok, data} <- Farmbot.JSON.decode(body)
    do
      hacked_data = %{data | "firmware_hardware" => get_config_value(:string, "settings", "firmware_hardware")}
      do_sync_fbos_configs(hacked_data)
    else
      {:ok, status_code: code} ->
        Farmbot.Logger.error 1, "HTTP error syncing settings: #{code}"
        :ok
      err ->
        Farmbot.Logger.error 1, "Error syncing settings: #{inspect err}"
        :ok
    end
  end

  def do_sync_fbos_configs(api_data) do
    update_config_value(:bool, "settings", "ignore_fbos_config", true)
      Farmbot.Logger.info 3, "API is the source of truth for Farmbot OS configs. Downloading data."
      old_config = get_config_as_map()["settings"]
      apply_fbos_map(old_config, api_data)
    update_config_value(:bool, "settings", "ignore_fbos_config", false)

    :ok
  end

  def take_valid_fbos(map) do
    Map.take(map, @fbos_keys ++ Enum.map(@fbos_keys, &String.to_atom(&1)))
  end

  def take_valid_fw(%{param_config_ok: _} = atom_map) do
    Map.new(atom_map, fn({key, val}) -> {to_string(key), val} end)
  end

  def take_valid_fw(map) do
    Map.take(map, @firmware_keys ++ Enum.map(@firmware_keys, &String.to_atom(&1)))
    |> Map.drop(["param_version", "param_test", "param_config_ok", "param_use_eeprom"])
  end
end
