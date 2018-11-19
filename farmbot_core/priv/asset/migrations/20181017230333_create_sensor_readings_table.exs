defmodule Farmbot.Asset.Repo.Migrations.CreateSensorReadingsTable do
  use Ecto.Migration

  def change do
    create table("sensor_readings", primary_key: false) do
      add(:local_id, :binary_id, primary_key: true)
      add(:id, :id)
      add(:mode, :integer)
      add(:pin, :integer)
      add(:value, :integer)
      add(:x, :float)
      add(:y, :float)
      add(:z, :float)
      add(:monitor, :boolean, default: true)
      timestamps(inserted_at: :created_at, type: :utc_datetime)
    end
  end
end
