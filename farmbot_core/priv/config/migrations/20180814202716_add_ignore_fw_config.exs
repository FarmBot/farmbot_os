defmodule Farmbot.System.ConfigStorage.Migrations.AddIgnoreFwConfig do
  use Ecto.Migration
  import Farmbot.Config

  def change do
    create_settings_config("ignore_fw_config", :bool, false)
  end
end
