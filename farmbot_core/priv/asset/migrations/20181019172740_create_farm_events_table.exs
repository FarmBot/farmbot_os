defmodule Farmbot.Asset.Repo.Migrations.CreateFarmEventsTable do
  use Ecto.Migration

  def change do
    create table("farm_events", primary_key: false) do
      add(:local_id, :binary_id, primary_key: true)
      add(:id, :id)
      add(:end_time, :utc_datetime)
      add(:executable_type, :string)
      add(:executable_id, :id)
      add(:repeat, :integer)
      add(:start_time, :utc_datetime)
      add(:time_unit, :string)
      add(:last_executed, :utc_datetime)
      add(:monitor, :boolean, default: true)
      timestamps(inserted_at: :created_at, type: :utc_datetime)
    end
  end
end
