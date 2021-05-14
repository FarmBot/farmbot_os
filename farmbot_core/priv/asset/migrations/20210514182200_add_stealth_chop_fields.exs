defmodule FarmbotCore.Asset.Repo.Migrations.AddStealthChopFields do
  use Ecto.Migration

  def change do
    alter table("firmware_configs") do
      add(:movement_calibration_deadzone_x, :float)
      add(:movement_calibration_deadzone_y, :float)
      add(:movement_calibration_deadzone_z, :float)
      add(:movement_axis_stealth_x, :float)
      add(:movement_axis_stealth_y, :float)
      add(:movement_axis_stealth_z, :float)
    end

    # will resync the firmware params
    execute(
      "UPDATE firmware_configs SET updated_at = \"1970-11-07 16:52:31.618000\""
    )
  end
end
