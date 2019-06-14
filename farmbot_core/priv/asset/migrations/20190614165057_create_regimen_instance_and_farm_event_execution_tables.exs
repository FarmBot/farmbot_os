defmodule FarmbotCore.Asset.Repo.Migrations.CreateRegimenInstanceAndFarmEventExecutionTables do
  use Ecto.Migration

  def change do
    create table("regimen_instance_executions", primary_key: false) do
      add(:local_id, :binary_id, primary_key: true)

      add(
        :regimen_instance_local_id,
        references("regimen_instances", type: :binary_id, column: :local_id)
      )

      add(:scheduled_at, :utc_datetime)
      add(:executed_at, :utc_datetime)
      add(:status, :string)
      timestamps(inserted_at: :created_at, type: :utc_datetime)
    end

    create table("farm_event_executions", primary_key: false) do
      add(:local_id, :binary_id, primary_key: true)

      add(
        :farm_event_local_id,
        references("farm_events", type: :binary_id, column: :local_id)
      )

      add(:scheduled_at, :utc_datetime)
      add(:executed_at, :utc_datetime)
      add(:status, :string)
      timestamps(inserted_at: :created_at, type: :utc_datetime)
    end
  end
end
