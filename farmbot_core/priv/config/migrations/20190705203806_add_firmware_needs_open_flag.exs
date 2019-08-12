defmodule FarmbotCore.Config.Repo.Migrations.AddFirmwareNeedsOpenFlag do
  use Ecto.Migration
  import FarmbotCore.Config, only: [update_config_value: 4]
  import FarmbotCore.Config.MigrationHelpers

  def change do
    update_config_value(:bool, "settings", "firmware_needs_flash", true)
    create_settings_config("firmware_needs_open", :bool, false)
  end
end
