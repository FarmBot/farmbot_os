defmodule Farmbot.Asset.Repo.Migrations.CreatePinBindingsTable do
  use Ecto.Migration

  def change do
    create table("pin_bindings", primary_key: false) do
      add(:local_id, :binary_id, primary_key: true)
      add(:id, :id)
      add(:pin_num, :integer)
      add(:sequence_id, :integer)
      add(:special_action, :string)
      add(:monitor, :boolean, default: true)
      timestamps(inserted_at: :created_at, type: :utc_datetime)
    end
  end
end
