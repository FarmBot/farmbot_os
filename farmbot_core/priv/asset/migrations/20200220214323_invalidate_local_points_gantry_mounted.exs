defmodule FarmbotCore.Asset.Repo.Migrations.InvalidateLocalPointsGantryMounted do
  use Ecto.Migration

  def change do
    execute("UPDATE points SET updated_at = \"1970-11-07 16:52:31.618000\"")
  end
end
