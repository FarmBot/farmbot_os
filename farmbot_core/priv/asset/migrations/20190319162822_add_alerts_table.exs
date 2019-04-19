defmodule FarmbotCore.Config.Repo.Migrations.AddAlertsTable do
  use Ecto.Migration

  def change do
    create table("alerts", primary_key: false) do
      add(:local_id, :binary_id, primary_key: true)
      add(:problem_tag, :string)
      add(:priority, :integer)
      add(:status, :string, default: "unresolved")

      add(:monitor, :boolean, default: true)
      timestamps(inserted_at: :created_at, type: :utc_datetime)
    end
  end
end
