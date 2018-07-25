defmodule Farmbot.Asset.Repo.Migrations.AddPointsTable do
  use Ecto.Migration

  def change do
    create table("points", primary_key: false) do
      add(:id, :integer)
      add(:name, :string)
      add(:x, :float)
      add(:y, :float)
      add(:z, :float)
      add(:meta, :text)
      add(:tool_id, :integer)
      add(:pointer_type, :string)
    end

    create(unique_index("points", [:id]))
  end
end
