defmodule Farmbot.System.ConfigStorage.Migrations.ArduinoDebugParam do
  use Ecto.Migration

  import Farmbot.System.ConfigStorage.MigrationHelpers

  def change do
    create_settings_config("arduino_debug_messages", :bool, false)
  end
end
