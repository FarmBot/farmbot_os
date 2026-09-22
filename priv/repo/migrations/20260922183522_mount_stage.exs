defmodule FarmbotOS.Asset.Repo.Migrations.MountStage do
  use Ecto.Migration

  def change do
    alter table("tools") do
      add(:type, :string)
      add(:utm_mountable, :boolean)
      add(:effector_offset_x, :float)
      add(:effector_offset_y, :float)
      add(:effector_offset_z, :float)
    end

    alter table("points") do
      add(:mount_stage, :integer)
      add(:mount_offset_x, :float)
      add(:mount_offset_y, :float)
      add(:mount_offset_z, :float)
    end

    alter table("peripherals") do
      add(:type, :string)
    end

    alter table("sensors") do
      add(:type, :string)
    end

    execute("UPDATE tools SET updated_at = \'1970-11-07 16:52:31.618000\';")

    execute("UPDATE points SET updated_at = \'1970-11-07 16:52:31.618000\';")

    execute(
      "UPDATE peripherals SET updated_at = \'1970-11-07 16:52:31.618000\';"
    )

    execute("UPDATE sensors SET updated_at = \'1970-11-07 16:52:31.618000\';")
  end
end
