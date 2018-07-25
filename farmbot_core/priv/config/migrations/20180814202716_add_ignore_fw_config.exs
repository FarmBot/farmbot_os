defmodule Farmbot.System.ConfigStorage.Migrations.AddIgnoreFwConfig do
  use Ecto.Migration
  import Farmbot.System.ConfigStorage.MigrationHelpers

  def change do
    create_settings_config("ignore_fw_config", :bool, false)
  end
end
