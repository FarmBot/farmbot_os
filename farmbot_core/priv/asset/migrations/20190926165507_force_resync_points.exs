defmodule FarmbotCore.Asset.Repo.Migrations.ForceResyncPoints do
  use Ecto.Migration

  alias FarmbotCore.Asset.{Repo, Point}

  def change do
    execute("TRUNCATE TABLE points;")
  end
end
