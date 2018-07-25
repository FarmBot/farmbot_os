defmodule Farmbot.BotState.Configuration do
  @moduledoc false
  defstruct [
    timezone: nil,
    sync_timeout_ms: nil,
    sequence_init_log: nil,
    sequence_complete_log: nil,
    sequence_body_log: nil,
    os_update_server_overwrite: nil,
    os_auto_update: nil,
    network_not_found_timer: nil,
    log_amqp_connected: nil,
    ignore_fbos_config: nil,
    ignore_external_logs: nil,
    fw_upgrade_migration: nil,
    first_sync: nil,
    first_party_farmware_url: nil,
    first_party_farmware: nil,
    first_boot: nil,
    firmware_output_log: nil,
    firmware_needs_first_sync: nil,
    firmware_input_log: nil,
    firmware_hardware: nil,
    email_on_estop: nil,
    disable_factory_reset: nil,
    currently_on_beta: nil,
    current_repo: nil,
    beta_opt_in: nil,
    auto_sync: nil,
    arduino_debug_messages: nil,
    api_migrated: nil
  ]
end
