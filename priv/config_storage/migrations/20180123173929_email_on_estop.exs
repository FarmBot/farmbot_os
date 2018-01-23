defmodule Farmbot.System.ConfigStorage.Migrations.EmailOnEstop do
  use Ecto.Migration

  import Farmbot.System.ConfigStorage.MigrationHelpers

  def change do
    create_settings_config("email_on_estop", :bool, true)
  end
end
