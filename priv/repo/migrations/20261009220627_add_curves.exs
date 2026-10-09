defmodule FarmbotOS.Asset.Repo.Migrations.AddCurves do
  use Ecto.Migration

  def change do
    create table("curves", primary_key: false) do
      add(:local_id, :binary_id, primary_key: true)
      add(:id, :id)
      add(:name, :string)
      add(:type, :string)
      add(:data, :map)
      add(:monitor, :boolean, default: true)
      timestamps(inserted_at: :created_at, type: :utc_datetime_usec)
    end

    create(unique_index(:curves, [:id]))

    alter table("syncs") do
      add(:curves, :map)
    end
  end
end
