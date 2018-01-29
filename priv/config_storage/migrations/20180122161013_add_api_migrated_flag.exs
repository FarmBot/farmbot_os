defmodule Farmbot.System.ConfigStorage.Migrations.AddApiMigratedFlag do
  use Ecto.Migration

  import Farmbot.System.ConfigStorage.MigrationHelpers

  def change do
    create_settings_config("api_migrated", :bool, false)
  end
end
