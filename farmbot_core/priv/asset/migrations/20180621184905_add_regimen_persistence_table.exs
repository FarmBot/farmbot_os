defmodule Farmbot.Asset.Repo.Migrations.AddRegimenPersistenceTable do
  use Ecto.Migration

  def change do
    create table("persistent_regimens") do
      add :regimen_id, :integer
      add :time, :utc_datetime
      add :farm_event_id, :integer
      timestamps()
    end
    unique_index("persistent_regimens", :regimen_id)
    create unique_index("persistent_regimens", [:regimen_id, :time, :farm_event_id], name: :regimen_start_time)
  end
end
