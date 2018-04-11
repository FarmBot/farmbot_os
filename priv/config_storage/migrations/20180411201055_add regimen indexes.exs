defmodule Farmbot.System.ConfigStorage.Migrations.AddRegimenIndexs do
  use Ecto.Migration

    def change do
       alter table("persistent_regimens") do
        add :farm_event_id, :integer
      end
      create unique_index("persistent_regimens", [:regimen_id, :time, :farm_event_id], name: :regimen_start_time)
    end
end
