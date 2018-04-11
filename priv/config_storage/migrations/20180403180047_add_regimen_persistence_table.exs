defmodule Farmbot.System.ConfigStorage.Migrations.AddRegimenPersistenceTable do
  use Ecto.Migration

  def change do
    create table("persistent_regimens") do
      add :regimen_id, :integer
      add :farm_event_id, :integer
      add :time, :utc_datetime
    end
    create unique_index("persistent_regimens", [:regimen_id, :time, :farm_event_id], name: :regimen_start_time)
  end
end
