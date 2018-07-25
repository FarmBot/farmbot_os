defmodule Farmbot.Asset.Repo.Migrations.AddSensorsTable do
  use Ecto.Migration

  def change do
    create table("sensors", primary_key: false) do
      add(:id, :integer)
      add(:pin, :integer)
      add(:mode, :integer)
      add(:label, :string)
    end

    create(unique_index("sensors", [:id]))
  end
end
