defmodule Farmbot.Asset.Repo.Migrations.AddFarmEventsTable do
  use Ecto.Migration

  def change do
    create table("farm_events", primary_key: false) do
      add(:id, :integer)
      add(:start_time, :string)
      add(:end_time, :string)
      add(:repeat, :integer)
      add(:time_unit, :string)
      add(:executable_type, :string)
      add(:executable_id, :integer)
      add(:calendar, :string)
    end

    create(unique_index("farm_events", [:id]))
  end
end
