defmodule Farmbot.System.ConfigStorage.Migrations.AddUpdateChannelField do
  use Ecto.Migration
  import Farmbot.System.ConfigStorage.MigrationHelpers

  def change do
    create_settings_config("update_channel", :string, nil)
  end
end
