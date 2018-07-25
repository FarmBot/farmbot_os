defmodule Farmbot.Config.Repo.Migrations.FirmwareInitializedFlag do
  use Ecto.Migration

  import Farmbot.Config.MigrationHelpers

  def change do
    create_settings_config("firmware_needs_first_sync", :bool, true)
  end
end
