defmodule FarmbotCore.Config.Repo.Migrations.AddBetaChanelConfig do
  use Ecto.Migration

  import FarmbotCore.Config.MigrationHelpers

  def change do
    create_settings_config("beta_opt_in", :bool, false)
    create_settings_config("os_update_server_overwrite", :string, nil)
  end
end
