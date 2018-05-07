defmodule Farmbot.System.ConfigStorage.Migrations.AddFirmwareIoLog do
  use Ecto.Migration

  import Farmbot.System.ConfigStorage.MigrationHelpers
  @io_logs Application.get_env(:farmbot, :firmware_io_logs, false)

  def change do
    create_settings_config("firmware_input_log", :bool, @io_logs)
    create_settings_config("firmware_output_log", :bool, @io_logs)
  end
end
