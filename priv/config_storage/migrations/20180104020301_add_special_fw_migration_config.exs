defmodule Farmbot.System.ConfigStorage.Migrations.AddSpecialFwMigrationConfig do
  use Ecto.Migration

  import Farmbot.System.ConfigStorage.MigrationHelpers

  def change do
    create_settings_config("fw_upgrade_migration", :bool, true)
  end
end
