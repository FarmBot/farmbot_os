defmodule Farmbot.System.ConfigStorage.Migrations.AddSequenceCompleteLogOption do
  use Ecto.Migration

  import Farmbot.System.ConfigStorage.MigrationHelpers

  def change do
    create_settings_config("sequence_init_log",     :bool, true)
    create_settings_config("sequence_body_log",     :bool, true)
    create_settings_config("sequence_complete_log", :bool, true)
  end
end
