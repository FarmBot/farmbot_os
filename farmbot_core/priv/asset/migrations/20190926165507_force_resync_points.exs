defmodule FarmbotCore.Asset.Repo.Migrations.ForceResyncPoints do
  use Ecto.Migration

  alias FarmbotCore.Asset.Repo

  def change do
    Repo.query("TRUNCATE points")
  end
end
