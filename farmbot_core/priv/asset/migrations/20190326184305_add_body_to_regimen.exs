defmodule FarmbotCore.Asset.Repo.Migrations.AddBodyToRegimen do
  use Ecto.Migration

  def change do
    # body
    alter table("regimens") do
      add(:body, {:array, :map})
    end
  end
end
