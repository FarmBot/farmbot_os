defmodule Farmbot.Config.Repo.Migrations.AddAmqpBootupLog do
  use Ecto.Migration

  import Farmbot.Config.MigrationHelpers

  def change do
    create_settings_config("log_amqp_connected", :bool, true)
  end
end
