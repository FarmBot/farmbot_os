defmodule Farmbot.System.ConfigStorage.Migrations.FirmwareInitializedFlag do
  use Ecto.Migration

  import Farmbot.System.ConfigStorage.MigrationHelpers

  def change do
    create_settings_config("firmware_needs_first_sync", :bool, true)
  end
end
