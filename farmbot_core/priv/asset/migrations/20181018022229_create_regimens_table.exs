defmodule Farmbot.Asset.Repo.Migrations.CreateRegimensTable do
  use Ecto.Migration

  def change do
    create table("regimens", primary_key: false) do
      add(:local_id, :binary_id, primary_key: true)
      add(:id, :id)
      add(:regimen_items, {:array, :map})
      add(:name, :string)
      add(:monitor, :boolean, default: true)
      timestamps(inserted_at: :created_at, type: :utc_datetime)
    end
  end
end
