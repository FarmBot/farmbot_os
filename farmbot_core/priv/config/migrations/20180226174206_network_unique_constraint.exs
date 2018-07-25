defmodule Farmbot.Config.Repo.Migrations.NetworkUniqueConstraint do
  use Ecto.Migration

  def change do
    create unique_index(:network_interfaces, [:name])
  end
end
