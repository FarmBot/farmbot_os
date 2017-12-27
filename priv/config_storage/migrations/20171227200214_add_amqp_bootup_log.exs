defmodule Farmbot.System.ConfigStorage.Migrations.AddAmqpBootupLog do
  use Ecto.Migration

  import Farmbot.System.ConfigStorage.MigrationHelpers

  def change do
    create_settings_config("log_amqp_connected", :bool, true)
  end
end
