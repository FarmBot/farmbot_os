defmodule FarmbotOS.Asset.Repo.Migrations.NovFirmwareUpdates do
  use Ecto.Migration

  def change do
    alter table("firmware_configs") do
      add(:movement_calibration_retry_total_x, :float)
      add(:movement_calibration_retry_total_y, :float)
      add(:movement_calibration_retry_total_z, :float)
    end
  end
end
