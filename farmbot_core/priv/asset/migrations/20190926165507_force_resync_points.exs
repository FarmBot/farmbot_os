defmodule FarmbotCore.Asset.Repo.Migrations.ForceResyncPoints do
  use Ecto.Migration

  alias FarmbotCore.Asset.{Repo, Point}

  def change do
    for %{id: id} = point when is_integer(id) <- Repo.all(Point) do
      Repo.delete!(point)
    end
  end
end
