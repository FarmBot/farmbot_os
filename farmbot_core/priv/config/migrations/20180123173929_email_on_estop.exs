defmodule FarmbotCore.Config.Repo.Migrations.EmailOnEstop do
  use Ecto.Migration

  import FarmbotCore.Config.MigrationHelpers

  def change do
    create_settings_config("email_on_estop", :bool, true)
  end
end
