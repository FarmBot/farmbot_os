defmodule Elixir.FarmbotCore.Asset.Repo.Migrations.CreateFarmwareEnvsTable do
  use Ecto.Migration

  def change do
    create table("farmware_envs", primary_key: false) do
      add(:local_id, :binary_id, primary_key: true)
      add(:id, :id)
      add(:key, :string)
      add(:value, :string)
      add(:monitor, :boolean, default: true)
      timestamps(inserted_at: :created_at, type: :utc_datetime)
    end
  end
end
