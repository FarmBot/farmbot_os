defmodule Farmbot.Config.Repo.Migrations.AddFirmwareFlashSetting do
  use Ecto.Migration
  import Farmbot.Config, only: [update_config_value: 4]
  import Farmbot.Config.MigrationHelpers

  def change do
    update_config_value(:string, "settings", "firmware_hardware", nil)
    create_settings_config("firmware_needs_flash", :bool, true)
  end
end
