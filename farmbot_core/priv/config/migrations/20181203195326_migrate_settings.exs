defmodule FarmbotCore.Config.Repo.Migrations.MigrateSettings do
  use Ecto.Migration
  import FarmbotCore.Config.MigrationHelpers

  def change do
    delete_settings_config("auto_sync", :bool)
    delete_settings_config("firmware_needs_migration", :bool)
    delete_settings_config("email_on_estop", :bool)
    delete_settings_config("disable_factory_reset", :bool)
    delete_settings_config("ignore_fbos_config", :bool)
    delete_settings_config("os_update_server_overwrite", :string)
    delete_settings_config("network_not_found_timer", :float)
    delete_settings_config("timezone", :string)
    delete_settings_config("first_party_farmware_url", :string)
    delete_settings_config("sync_timeout_ms", :float)
    delete_settings_config("ignore_external_logs", :bool)
    delete_settings_config("needs_http_sync", :bool)
    delete_settings_config("currently_on_beta", :bool)
    delete_settings_config("arduino_debug_messages", :bool)
    delete_settings_config("firmware_output_log", :bool)
    delete_settings_config("firmware_input_log", :bool)
    delete_settings_config("beta_opt_in", :bool)
    delete_settings_config("log_amqp_connected", :bool)
    delete_settings_config("current_repo", :string)
    delete_settings_config("user_env", :string)
    delete_settings_config("sequence_complete_log", :bool)
    delete_settings_config("sequence_init_log", :bool)
    delete_settings_config("sequence_body_log", :bool)
    delete_settings_config("ignore_fw_config", :bool)
    delete_settings_config("api_migrated", :bool)
    delete_settings_config("firmware_needs_first_sync", :bool)
    delete_settings_config("first_boot", :bool)
  end
end
