defmodule FarmbotCore.Asset.Repo.Migrations.ForceResyncFbosConfig do
  use Ecto.Migration
  alias FarmbotCore.Asset.{Repo, FbosConfig}

  def change do
    if fbos_config = Repo.one(FbosConfig) do
      execute("UPDATE fbos_configs SET updated_at = \"1970-11-07 16:52:31.618000\"")
    end
  end
end
