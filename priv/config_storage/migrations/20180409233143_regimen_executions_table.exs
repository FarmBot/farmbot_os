defmodule Farmbot.System.ConfigStorage.Migrations.RegimenExecutionsTable do
  use Ecto.Migration

  def change do
    create table(:regimen_executions) do
      add :regimen_id, :integer
      add :executable_id, :integer
      add :epoch, :utc_datetime
      add :hash, :string
    end
    create(unique_index(:regimen_executions, [:regimen_id, :executable_id, :epoch, :hash]))
  end
end
