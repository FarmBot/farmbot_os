defmodule FarmbotCore.Asset.Repo.Migrations.AddNeedsResetToDevice do
  use Ecto.Migration

  def change do
    alter table("devices") do
      add(:needs_reset, :boolean, default: false)
    end

    # Invalidate cache of local device resource:
    execute("UPDATE devices SET updated_at = \"1970-11-07 16:52:31.618000\"")
  end
end
