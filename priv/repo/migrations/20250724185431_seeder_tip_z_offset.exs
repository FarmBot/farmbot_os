defmodule FarmbotOS.Asset.Repo.Migrations.SeederTipZOffset do
  use Ecto.Migration

  def change do
    alter table("tools") do
      add(:seeder_tip_z_offset, :float)
    end

    execute("UPDATE tools SET updated_at = \'1970-11-07 16:52:31.618000\';")
  end
end
