defmodule FarmbotCore.Asset.Repo.Migrations.ForceResyncDevice do
  use Ecto.Migration
  alias FarmbotCore.Asset.{Repo, Device}

  def change do
    if device = Repo.one(Device) do
      execute("UPDATE devices SET updated_at = \"1970-11-07 16:52:31.618000\"")
    end
  end
end
