defmodule FarmbotCore.Config.Repo.Migrations.IgnoreFbosConfig do
  use Ecto.Migration

  import FarmbotCore.Config.MigrationHelpers

  def change do
    create_settings_config("ignore_fbos_config", :bool, true)
  end
end
