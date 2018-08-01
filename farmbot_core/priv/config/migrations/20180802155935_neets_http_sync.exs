defmodule Farmbot.Config.Repo.Migrations.NeetsHttpSync do
  use Ecto.Migration
  import Farmbot.Config.MigrationHelpers

  def change do
    create_settings_config("needs_http_sync", :bool, true)
  end
end
