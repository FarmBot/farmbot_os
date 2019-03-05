defmodule FarmbotCore.Config.Migrations.AddUpdateChannelField do
  use Ecto.Migration
  import FarmbotCore.Config.MigrationHelpers

  def change do
    create_settings_config("update_channel", :string, nil)
  end
end
