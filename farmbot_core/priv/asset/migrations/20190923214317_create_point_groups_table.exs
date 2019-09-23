defmodule FarmbotCore.Asset.Repo.Migrations.CreatePointGroupsTable do
  use Ecto.Migration

  def change do
    create table("point_groups", primary_key: false) do
      add(:local_id, :binary_id, primary_key: true)
      add(:monitor, :boolean, default: true)

      add(:id, :id)
      add(:name, :string)
      add(:point_ids, {:array, :integer})

      timestamps(inserted_at: :created_at, type: :utc_datetime)
    end

    create(unique_index("point_groups", :id))

    alter table("syncs") do
      add(:point_groups, {:array, :map})
    end
  end
end
