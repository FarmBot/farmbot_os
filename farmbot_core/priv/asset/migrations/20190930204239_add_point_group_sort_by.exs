defmodule FarmbotCore.Asset.Repo.Migrations.AddPointGroupSortBy do
  use Ecto.Migration

  def change do
    alter table("point_groups") do
      add(:sort_type, :string)
    end
  end
end
