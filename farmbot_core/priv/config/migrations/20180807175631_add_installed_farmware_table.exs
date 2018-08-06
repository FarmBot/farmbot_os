defmodule Farmbot.Config.Repo.Migrations.AddInstalledFarmwareTable do
  use Ecto.Migration

  def change do
    create table("installed_farmwares") do
      add :installed_version, :string
      add :url, :string
      timestamps()
    end
  end
end
