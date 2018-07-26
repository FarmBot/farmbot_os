defmodule Farmbot.Repo.Migrations.CreatePinBindingsTable do
  use Ecto.Migration

  def change do
    create table("pin_bindings", primary_key: false) do
      add(:id, :integer)
      add(:pin_num, :integer)
      add(:sequence_id, :integer)
    end

    create(unique_index("pin_bindings", [:id]))
  end
end
