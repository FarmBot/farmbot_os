defmodule Farmbot.Repo.Migrations.AddFarmEventsTable do
  use Ecto.Migration

  def change do
    create table("farm_events", primary_key: false) do
      add(:id, :integer)
      add(:start_time, :utc_datetime)
      add(:end_time, :utc_datetime)
      add(:repeat, :integer)
      add(:time_unit, :string)
      add(:executable_type, :string)
      add(:executable_id, :integer)
    end

    create(unique_index("farm_events", [:id]))
  end
end
