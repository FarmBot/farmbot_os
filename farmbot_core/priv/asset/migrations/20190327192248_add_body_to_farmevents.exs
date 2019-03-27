defmodule FarmbotCore.Asset.Repo.Migrations.AddBodyToFarmevents do
  use Ecto.Migration

  def change do
    # body
    alter table("farm_events") do
      add(:body, {:array, :map})
    end
  end
end
