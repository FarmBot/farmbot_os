defmodule Farmbot.Asset.Repo.Migrations.CreateFarmwareEnvTable do
  use Ecto.Migration

  def change do
    create table("farmware_envs", primary_key: false) do
      add(:id, :integer)
      add(:key, :string)
      add(:value, :text)
    end

    create(unique_index("farmware_envs", [:id]))
  end
end
