defmodule FarmbotCore.Asset.Repo.Migrations.CreatePublicKeysTable do
  use Ecto.Migration

  def change do
    create table("public_keys", primary_key: false) do
      add(:local_id, :binary_id, primary_key: true)
      add(:id, :id)
      add(:name, :string)
      add(:public_key, :string)
      add(:monitor, :boolean, default: true)
      timestamps(inserted_at: :created_at, type: :utc_datetime)
    end

    create(unique_index("public_keys", :id))

    alter table("syncs") do
      add(:public_keys, {:array, :map})
    end
  end
end
