defmodule FarmbotCore.Config.Repo.Migrations.NeetsHttpSync do
  use Ecto.Migration
  import FarmbotCore.Config.MigrationHelpers

  def change do
    create_settings_config("needs_http_sync", :bool, true)
  end
end
