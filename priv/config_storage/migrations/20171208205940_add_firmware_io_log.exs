defmodule Farmbot.System.ConfigStorage.Migrations.AddFirmwareIoLog do
  use Ecto.Migration

  import Farmbot.System.ConfigStorage.MigrationHelpers

  def change do
    create_settings_config("firmware_input_log", :bool, false)
    create_settings_config("firmware_output_log", :bool, false)
  end
end
