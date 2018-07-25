defmodule Farmbot.Config.Repo.Migrations.ArduinoDebugParam do
  use Ecto.Migration

  import Farmbot.Config.MigrationHelpers

  def change do
    create_settings_config("arduino_debug_messages", :bool, true)
  end
end
