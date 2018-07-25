defmodule Farmbot.Asset.Repo.Migrations.AddGenericPointersTable do
  use Ecto.Migration

  def change do
    create table("generic_pointers", primary_key: false) do
      add(:id, :integer)
    end

    create(unique_index("generic_pointers", [:id]))
  end
end
