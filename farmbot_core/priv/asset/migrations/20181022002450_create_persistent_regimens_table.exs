defmodule Farmbot.Asset.Repo.Migrations.CreatePersistentRegimensTable do
  use Ecto.Migration
  def change do
    create table("persistent_regimens", primary_key: false) do
      add(:local_id, :binary_id, primary_key: true)
      add(:started_at, :utc_datetime)
      add(:regimen_id, references("regimens", type: :binary_id, column: :local_id))
      add(:farm_event_id, references("farm_events", type: :binary_id, column: :local_id))
      timestamps(inserted_at: :created_at, type: :utc_datetime)
    end

    create unique_index("persistent_regimens", [:local_id, :regimen_id, :farm_event_id])
    create unique_index("persistent_regimens", :started_at)
  end
end
