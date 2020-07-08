defmodule FarmbotCore.Config.Repo.Migrations.AddFirmwareNeedsOpenFlag do
  use Ecto.Migration
  import FarmbotCore.Config.MigrationHelpers

  def change do
    create_settings_config("firmware_needs_open", :bool, false)
  end
end
