defmodule FarmbotCore.Asset.Repo.Migrations.AddSoilHeightSafeHeight do
  use Ecto.Migration

  def change do
    alter table("fbos_configs") do
      add(:safe_height, :float)
      add(:soil_height, :float)
    end

    # will resync the firmware params
    execute(
      "UPDATE fbos_configs SET updated_at = \"1970-11-07 16:52:31.618000\""
    )
  end
end
