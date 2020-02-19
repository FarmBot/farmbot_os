defmodule FarmbotCore.Asset.Repo.Migrations.AddGantryMountedFields do
  use Ecto.Migration

  def change do
    alter table(:points) do
      add(:gantry_mounted, :boolean, default: false)
    end

    # Invalidate cache of local device resource:
    execute("UPDATE points SET updated_at = \"1970-11-07 16:52:31.618000\"")
  end
end

# farmbot_core/priv/asset/migrations/20190926161914_add_point_discarded_at.exs
# farmbot_core/priv/repo/migrations/20200219001135_add_gantry_mounted_fields.exs
