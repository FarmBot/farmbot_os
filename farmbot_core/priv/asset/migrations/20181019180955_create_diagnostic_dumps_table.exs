defmodule Elixir.Farmbot.Asset.Repo.Migrations.CreateDiagnosticDumpsTable do
  use Ecto.Migration

  def change do
    create table("diagnostic_dumps", primary_key: false) do
      add(:local_id, :binary_id, primary_key: true)
      add(:id, :id)
      add(:ticket_identifier, :string)
      add(:fbos_commit, :string)
      add(:fbos_version, :string)
      add(:firmware_commit, :string)
      add(:firmware_state, :string)
      add(:network_interface, :string)
      add(:fbos_dmesg_dump, :string)
      timestamps(inserted_at: :created_at, type: :utc_datetime)
    end
  end
end
