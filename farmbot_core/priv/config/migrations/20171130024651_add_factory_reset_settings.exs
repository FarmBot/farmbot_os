defmodule FarmbotCore.Config.Repo.Migrations.AddFactoryResetSettings do
  use Ecto.Migration
  import FarmbotCore.Config.MigrationHelpers

  def change do
    create_settings_config("disable_factory_reset", :bool, false)
    create_settings_config("network_not_found_timer", :float, nil)
  end
end
