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
