defmodule Elixir.FarmbotCore.Asset.Repo.Migrations.CreateDeviceCertsTable do
  use Ecto.Migration

  def change do
    create table("device_certs", primary_key: false) do
      add(:local_id, :binary_id, primary_key: true)
      add(:id, :id)
      add(:serial_number, :string)
      add(:tags, {:array, :string})
      timestamps(inserted_at: :created_at, type: :utc_datetime)
    end
  end
end
