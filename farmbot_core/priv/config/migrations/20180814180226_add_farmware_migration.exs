defmodule Farmbot.Config.Repo.Migrations.AddFarmwareMigration do
  use Ecto.Migration
  import Farmbot.Config.MigrationHelpers

  @default Farmbot.Project.version == "6.5.0"

  def change do
    create_settings_config("firmware_needs_migration", :bool, @default)
  end
end
