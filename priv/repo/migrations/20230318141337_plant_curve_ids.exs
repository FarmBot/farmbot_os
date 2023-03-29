defmodule FarmbotOS.Asset.Repo.Migrations.PlantCurveIds do
  use Ecto.Migration

  def change do
    alter table("points") do
      add(:depth, :integer)
      add(:water_curve_id, :integer)
      add(:spread_curve_id, :integer)
      add(:height_curve_id, :integer)
    end

    execute("UPDATE points SET updated_at = \'1970-11-07 16:52:31.618000\';")
  end
end
