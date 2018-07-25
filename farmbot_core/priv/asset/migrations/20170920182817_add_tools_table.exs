defmodule Farmbot.Asset.Repo.Migrations.AddToolsTable do
  use Ecto.Migration

  def change do
    create table("tools", primary_key: false) do
      add(:id, :integer)
      add(:name, :string)
    end

    create(unique_index("tools", [:id]))
  end
end
