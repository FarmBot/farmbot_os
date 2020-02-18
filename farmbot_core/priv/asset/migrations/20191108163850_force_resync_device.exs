defmodule FarmbotCore.Asset.Repo.Migrations.ForceResyncDevice do
  use Ecto.Migration

  def change do
    execute("UPDATE devices SET updated_at = \"1970-11-07 16:52:31.618000\"")
  end
end
