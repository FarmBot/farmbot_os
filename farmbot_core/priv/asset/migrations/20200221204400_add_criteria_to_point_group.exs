defmodule FarmbotCore.Asset.Repo.Migrations.AddCriteriaToPointGroup do
  use Ecto.Migration

  def change do
    alter table("point_groups") do
      add(:criteria, :text)
    end

    execute(
      "UPDATE point_groups SET updated_at = \"1970-11-07 16:52:31.618000\""
    )
  end
end
