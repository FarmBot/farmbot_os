defmodule Farmbot.Config.Repo.Migrations.AddSyncTimeout do
  use Ecto.Migration
  import Farmbot.Config.MigrationHelpers

  def change do
    create_settings_config("sync_timeout_ms", :float, 90_000.00)
  end
end
