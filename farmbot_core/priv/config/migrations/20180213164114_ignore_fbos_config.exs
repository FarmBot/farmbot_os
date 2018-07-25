defmodule Farmbot.Config.Repo.Migrations.IgnoreFbosConfig do
  use Ecto.Migration

  import Farmbot.Config.MigrationHelpers

  def change do
    create_settings_config("ignore_fbos_config", :bool, true)
  end
end
