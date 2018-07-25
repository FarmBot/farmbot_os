defmodule Farmbot.Config.Repo.Migrations.AddApiMigratedFlag do
  use Ecto.Migration

  import Farmbot.Config.MigrationHelpers

  def change do
    create_settings_config("api_migrated", :bool, false)
  end
end
