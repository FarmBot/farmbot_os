defmodule FarmbotOS.Asset.Repo.Migrations.RegimenInstanceBug do
  use Ecto.Migration

  @migrations [
    "DROP INDEX IF EXISTS regimen_start_time;",
    "DROP INDEX IF EXISTS persistent_regimens_epoch_index;",
    "DROP INDEX IF EXISTS persistent_regimens_local_id_regimen_id_farm_event_id_index;",
    "DROP INDEX IF EXISTS persistent_regimens_started_at_index;",
    "DROP INDEX IF EXISTS regimen_instances_started_at_index;",
    "UPDATE farm_events SET updated_at = \'1970-11-07 16:52:31.618000\';"
  ]
  def change, do: Enum.map(@migrations, &execute/1)
end
