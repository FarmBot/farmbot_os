defmodule FarmbotCore.Asset.Repo.Migrations.AddApiMigratedToFwConfig do
  use Ecto.Migration

  def change do
    alter table("firmware_configs") do
      add(:api_migrated, :boolean)
    end
  end
end
