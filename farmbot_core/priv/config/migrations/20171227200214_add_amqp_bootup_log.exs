defmodule FarmbotCore.Config.Repo.Migrations.AddAmqpBootupLog do
  use Ecto.Migration

  import FarmbotCore.Config.MigrationHelpers

  def change do
    create_settings_config("log_amqp_connected", :bool, true)
  end
end
