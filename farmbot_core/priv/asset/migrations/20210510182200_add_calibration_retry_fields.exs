defmodule FarmbotCore.Asset.Repo.Migrations.AddCalibrationRetryFields do
  use Ecto.Migration

  def change do
    alter table("firmware_configs") do
      add(:movement_calibration_retry_x, :float)
      add(:movement_calibration_retry_y, :float)
      add(:movement_calibration_retry_z, :float)
    end

    # will resync the firmware params
    execute(
      "UPDATE fbos_configs SET updated_at = \"1970-11-07 16:52:31.618000\""
    )
  end
end
