defmodule FarmbotCore.Config.Repo.Migrations.AddSpecialFwMigrationConfig do
  use Ecto.Migration

  import FarmbotCore.Config.MigrationHelpers

  def change do
    create_settings_config("fw_upgrade_migration", :bool, true)
  end
end
