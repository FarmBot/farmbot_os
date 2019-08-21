defmodule FarmbotOS.Lua.Ext.Info do
  alias FarmbotCeleryScript.SysCalls

  @doc """
  # Example Usage

  ## With channels

      farmbot.send_message("info", "hello, world", ["email", "toast"])

  ## No channels

      farmbot.send_message("info", "hello, world")

  """
  def send_message([kind, message], lua) do
    do_send_message(kind, message, [], lua)
  end

  def send_message([kind, message | channels], lua) do
    channels = Enum.map(channels, &String.to_atom/1)
    do_send_message(kind, message, channels, lua)
  end

  def read_status(_, lua) do
    bot_state = FarmbotCore.BotState.fetch()

    configuration_table = [
      {"arduino_debug_messages", bot_state.configuration.arduino_debug_messages},
      {"auto_sync", bot_state.configuration.auto_sync},
      {"beta_opt_in", bot_state.configuration.beta_opt_in},
      {"disable_factory_reset", bot_state.configuration.disable_factory_reset},
      {"firmware_hardware", bot_state.configuration.firmware_hardware},
      {"firmware_input_log", bot_state.configuration.firmware_input_log},
      {"firmware_output_log", bot_state.configuration.firmware_output_log},
      {"network_not_found_timer", bot_state.configuration.network_not_found_timer},
      {"os_auto_update", bot_state.configuration.os_auto_update},
      {"sequence_body_log", bot_state.configuration.sequence_body_log},
      {"sequence_complete_log", bot_state.configuration.sequence_complete_log},
      {"sequence_init_log", bot_state.configuration.sequence_init_log}
    ]

    informational_settings_table = [
      {"busy", bot_state.informational_settings.busy},
      {"cache_bust", bot_state.informational_settings.cache_bust},
      {"commit", bot_state.informational_settings.commit},
      {"controller_version", bot_state.informational_settings.controller_version},
      {"disk_usage", bot_state.informational_settings.disk_usage},
      {"env", bot_state.informational_settings.env},
      {"firmware_commit", bot_state.informational_settings.firmware_commit},
      {"firmware_version", bot_state.informational_settings.firmware_version},
      {"idle", bot_state.informational_settings.idle},
      {"last_status", bot_state.informational_settings.last_status},
      {"locked", bot_state.informational_settings.locked},
      {"memory_usage", bot_state.informational_settings.memory_usage},
      {"node_name", bot_state.informational_settings.node_name},
      {"soc_temp", bot_state.informational_settings.soc_temp},
      {"sync_status", bot_state.informational_settings.sync_status},
      {"target", bot_state.informational_settings.target},
      {"throttled", bot_state.informational_settings.throttled},
      {"update_available", bot_state.informational_settings.update_available},
      {"uptime", bot_state.informational_settings.uptime},
      {"wifi_level", bot_state.informational_settings.wifi_level},
      {"wifi_level_percent", bot_state.informational_settings.wifi_level_percent}
    ]

    location_data_table = [
      {"position",
       [
         {"x", bot_state.location_data.position.x},
         {"y", bot_state.location_data.position.y},
         {"z", bot_state.location_data.position.z}
       ]},
      {"raw_encoders",
       [
         {"x", bot_state.location_data.raw_encoders.x},
         {"y", bot_state.location_data.raw_encoders.y},
         {"z", bot_state.location_data.raw_encoders.z}
       ]},
      {"scaled_encoders",
       [
         {"x", bot_state.location_data.scaled_encoders.x},
         {"y", bot_state.location_data.scaled_encoders.y},
         {"z", bot_state.location_data.scaled_encoders.z}
       ]}
    ]

    final_table = [
      {"configuration", configuration_table},
      {"informational_settings", informational_settings_table},
      {"location_data", location_data_table}
    ]

    {[final_table, nil], lua}
  end

  @doc "Returns the current version of farmbot."
  def version(_args, lua) do
    {[FarmbotCore.Project.version(), nil], lua}
  end

  defp do_send_message(kind, message, channels, lua) do
    case SysCalls.send_message(kind, message, channels) do
      :ok ->
        {[true, nil], lua}

      {:error, reason} ->
        {[nil, reason], lua}
    end
  end
end
