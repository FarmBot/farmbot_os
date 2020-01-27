defmodule FarmbotCore.Asset.Repo.Migrations.ResyncFirmwareConfig do
  use Ecto.Migration

  def change do
    alter table("firmware_configs") do
      add(:movement_microsteps_x, :float)
      add(:movement_microsteps_y, :float)
      add(:movement_microsteps_z, :float)
    end

    # will resync the firmware params
    execute(
      "UPDATE firmware_configs SET updated_at = \"1970-11-07 16:52:31.618000\""
    )
  end
end
