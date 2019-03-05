defmodule FarmbotCore.Config.Repo.Migrations.AddSequenceCompleteLogOption do
  use Ecto.Migration

  import FarmbotCore.Config.MigrationHelpers

  def change do
    create_settings_config("sequence_init_log", :bool, true)
    create_settings_config("sequence_body_log", :bool, true)
    create_settings_config("sequence_complete_log", :bool, true)
  end
end
