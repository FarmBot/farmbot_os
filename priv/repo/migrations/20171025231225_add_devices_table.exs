defmodule Farmbot.Repo.Migrations.AddDevicesTable do
  use Ecto.Migration

  def change do
    create table("devices", primary_key: false) do
      add(:id, :integer)
      add(:name, :string)
      add(:timezone, :string)
    end

    create(unique_index("devices", [:id]))
  end
end
