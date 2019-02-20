defmodule Farmbot.System.ConfigStorage.Migrations.AddUpdateChannelField do
  use Ecto.Migration
  import Farmbot.Config.MigrationHelpers

  def change do
    create_settings_config("update_channel", :string, nil)
  end
end
