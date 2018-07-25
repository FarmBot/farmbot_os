defmodule Farmbot.Config.Repo.Migrations.AddFirmwareIoLog do
  use Ecto.Migration

  import Farmbot.Config.MigrationHelpers
  @io_logs Application.get_env(:farmbot_core, :firmware_io_logs, false)

  def change do
    create_settings_config("firmware_input_log", :bool, @io_logs)
    create_settings_config("firmware_output_log", :bool, @io_logs)
  end
end
