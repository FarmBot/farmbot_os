defmodule FarmbotCore.Asset.Repo.Migrations.ForceResyncPoints do
  use Ecto.Migration

  alias FarmbotCore.Asset.{Repo, Point}
  import Ecto.Query, only: [from: 2]

  def change do
    for %{id: id} = point when is_integer(id) <- Repo.all(Point) do
      Repo.delete!(point)
    end
  end
end
