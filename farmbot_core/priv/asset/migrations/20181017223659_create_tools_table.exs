defmodule Farmbot.Asset.Repo.Migrations.CreateToolsTable do
  use Ecto.Migration

  def change do
    create table("tools", primary_key: false) do
      add(:local_id, :binary_id, primary_key: true)
      add(:id, :id)
      add(:name, :string)
      add(:monitor, :boolean, default: true)
      timestamps(inserted_at: :created_at, type: :utc_datetime)
    end
  end
end
