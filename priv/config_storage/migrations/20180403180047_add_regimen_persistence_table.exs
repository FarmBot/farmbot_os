defmodule Farmbot.System.ConfigStorage.Migrations.AddRegimenPersistenceTable do
  use Ecto.Migration

  def change do
    create table("persistent_regimens") do
      add :regimen_id, :integer
      add :time, :utc_datetime
    end
    unique_index("persistent_regimens", :regimen_id)
  end
end
