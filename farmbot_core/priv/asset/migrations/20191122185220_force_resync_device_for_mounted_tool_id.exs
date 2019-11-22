defmodule FarmbotCore.Asset.Repo.Migrations.ForceResyncDeviceForMountedToolId do
  use Ecto.Migration
  alias FarmbotCore.Asset.{Repo, Device}

  def change do
    execute("UPDATE devices SET updated_at = \"1970-11-07 16:52:31.618000\"")
  end
end
