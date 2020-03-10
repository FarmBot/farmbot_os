defmodule FarmbotCore.Asset.Repo.Migrations.AddOpenfarmSlugToPoint do
  use Ecto.Migration

  def change do
    alter table("points") do
      add(:openfarm_slug, :string)
    end

    execute("UPDATE points SET updated_at = \"1970-11-07 16:52:31.618000\"")
  end
end
