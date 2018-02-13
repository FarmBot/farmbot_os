defmodule Farmbot.System.ConfigStorage.Migrations.IgnoreFbosConfig do
  use Ecto.Migration

  import Farmbot.System.ConfigStorage.MigrationHelpers

  def change do
    create_settings_config("ignore_fbos_config", :bool, true)
  end
end
