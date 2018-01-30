defmodule Farmbot.Bootstrap.SettingsSync do
  @moduledoc "Handles uploading and downloading of FBOS configs."
  use Task, restart: :transient
  use Farmbot.Logger
  import Farmbot.System.ConfigStorage, only: [get_config_value: 3, update_config_value: 4, get_config_as_map: 0]

  def start_link() do
    Task.start_link(__MODULE__, :run, [])
  end

  def run() do
    with {:ok, %{body: body, status_code: 200}} <- Farmbot.HTTP.get("/api/fbos_config"),
    {:ok, data} <- Poison.decode(body)
    do
      do_sync_settings(data)
    else
      {:ok, status_code: code} ->
        Logger.error 1, "HTTP error syncing settings: #{code}"
        :ok
      err ->
        Logger.error 1, "Error syncing settings: #{inspect err}"
        :ok
    end
  rescue
    err ->
      Logger.error 1, "Error syncing settings: #{Exception.message(err)} #{inspect System.stacktrace()}"
  end

  def apply_map(old_map, new_map) do
    old_map = take_valid(old_map)
    new_map = take_valid(new_map)
    Map.new(new_map, fn({key, new_value}) ->
      # Logger.debug 1, "Applying #{key} #{inspect old_map[key]} over #{inspect new_value}"
      if old_map[key] != new_value do
        case new_value do
          val when is_boolean(val) ->
            update_config_value(:bool, "settings", key, new_value)
          val when is_binary(val) ->
            update_config_value(:string, "settings", key, new_value)
          val when is_number(val) ->
            update_config_value(:float, "settings", key, new_value / 1)
        end
        Logger.success 1, "Updating: #{key} => #{new_value}"
      end
      {key, new_value}
    end)
  end

  def do_sync_settings(%{"api_migrated" => true} = api_data) do
    Logger.info 3, "API is the source of truth; Downloading data."
    old_config = get_config_as_map()["settings"]
    apply_map(old_config, api_data)
    :ok
  end

  def do_sync_settings(_unimportant_data) do
    Logger.info 3, "FBOS is the source of truth; Uploading data."
    auto_sync = get_config_value(:bool, "settings", "auto_sync")
    beta_opt_in = get_config_value(:bool, "settings", "beta_opt_in")
    disable_factory_reset = get_config_value(:bool, "settings", "disable_factory_reset")
    firmware_output_log = get_config_value(:bool, "settings", "firmware_output_log")
    sequence_body_log = get_config_value(:bool, "settings", "sequence_body_log")
    sequence_complete_log = get_config_value(:bool, "settings", "sequence_complete_log")
    sequence_init_log = get_config_value(:bool, "settings", "sequence_init_log")
    arduino_debug_messages = get_config_value(:bool, "settings", "arduino_debug_messages")
    os_auto_update = get_config_value(:bool, "settings", "os_auto_update")
    firmware_hardware = get_config_value(:string, "settings", "firmware_hardware")
    network_not_found_timer = get_config_value(:float, "settings", "network_not_found_timer")
    payload = %{
      api_migrated: true,
      auto_sync: auto_sync,
      beta_opt_in: beta_opt_in,
      disable_factory_reset: disable_factory_reset,
      firmware_output_log: firmware_output_log,
      sequence_body_log: sequence_body_log,
      sequence_complete_log: sequence_complete_log,
      sequence_init_log: sequence_init_log,
      arduino_debug_messages: arduino_debug_messages,
      os_auto_update: os_auto_update,
      firmware_hardware: firmware_hardware,
      network_not_found_timer: network_not_found_timer,
    } |> Poison.encode!()
    Farmbot.HTTP.delete!("/api/fbos_config")
    Farmbot.HTTP.put!("/api/fbos_config", payload)
    :ok
  end

  @keys [
    "auto_sync",
    "beta_opt_in",
    "disable_factory_reset",
    "firmware_output_log",
    "sequence_body_log",
    "sequence_complete_log",
    "sequence_init_log",
    "arduino_debug_messages",
    "os_auto_update",
    "firmware_hardware",
    "network_not_found_timer"
  ]
  def take_valid(map) do
    Map.take(map, @keys ++ Enum.map(@keys, &String.to_atom(&1)))
  end
end
