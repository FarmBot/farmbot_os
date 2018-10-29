defmodule Farmbot.Asset.Repo.Migrations.CreateDevicesTable do
  use Ecto.Migration

  def change do
    create table("devices", primary_key: false) do
      add(:local_id, :binary_id, primary_key: true)
      add(:id, :id)
      add(:name, :string)
      add(:timezone, :string)
      timestamps(inserted_at: :created_at, type: :utc_datetime)
    end
  end
end
