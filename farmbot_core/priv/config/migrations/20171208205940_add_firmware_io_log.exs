defmodule Farmbot.Config.Repo.Migrations.AddFirmwareIoLog do
  use Ecto.Migration

  import Farmbot.Config.MigrationHelpers
  @default_firmware_io_logs Application.get_env(:farmbot_core, :default_firmware_io_logs, false)

  def change do
    create_settings_config("firmware_input_log", :bool, @default_firmware_io_logs)
    create_settings_config("firmware_output_log", :bool, @default_firmware_io_logs)
  end
end
