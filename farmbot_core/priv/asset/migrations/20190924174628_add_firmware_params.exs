defmodule FarmbotCore.Asset.Repo.Migrations.AddFirmwareParams do
  use Ecto.Migration

  def change do
    alter table("firmware_configs") do
      add(:movement_motor_current_x, :float)
      add(:movement_motor_current_y, :float)
      add(:movement_motor_current_z, :float)
      add(:movement_stall_sensitivity_x, :float)
      add(:movement_stall_sensitivity_y, :float)
      add(:movement_stall_sensitivity_z, :float)
    end
  end
end
