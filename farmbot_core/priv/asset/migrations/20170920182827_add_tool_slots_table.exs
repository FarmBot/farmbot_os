defmodule Farmbot.Asset.Repo.Migrations.AddToolSlotsTable do
  use Ecto.Migration

  def change do
    create table("tool_slots", primary_key: false) do
      add(:id, :integer)
      add(:tool_id, :integer)
    end

    create(unique_index("tool_slots", [:id]))
  end
end
