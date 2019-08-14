defmodule FarmbotCore.Asset.Repo.Migrations.CreateFirstPartyFarmwareTable do
  use Ecto.Migration

  def change do
    create table("first_party_farmwares", primary_key: false) do
      add(:local_id, :binary_id, primary_key: true)
      add(:id, :id)
      add(:url, :string)
      add(:manifest, :map)
      add(:monitor, :boolean, default: true)
      timestamps(inserted_at: :created_at, type: :utc_datetime)
    end

    create(unique_index("first_party_farmwares", :id))

    alter table("syncs") do
      add(:first_party_farmwares, {:array, :map})
    end
  end
end
