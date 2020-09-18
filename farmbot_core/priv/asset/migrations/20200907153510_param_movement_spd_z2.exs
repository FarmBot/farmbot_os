defmodule FarmbotCore.Asset.Repo.Migrations.ParamMovementSpdZ2 do
  use Ecto.Migration

  def change do
    alter table("firmware_configs") do
      add(:movement_max_spd_z2, :float)
      add(:movement_min_spd_z2, :float)
      add(:movement_steps_acc_dec_z2, :float)
    end
  end
end
