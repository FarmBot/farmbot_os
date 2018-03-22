defmodule Farmbot.Repo.Migrations.FixNamespaces do
  use Ecto.Migration
  import Ecto.Query

  def change do
    repo = Application.get_env(:farmbot, :repo_hack)
    if repo do
      do_update(repo)
    else
      IO.puts "Not migrating."
    end
  end

  defp do_update(repo) do
    fe_needs_change = repo.all(from e in Farmbot.Asset.FarmEvent)
    |> Enum.filter(fn(asset) ->
      String.contains?(asset.executable_type, "Repo")
    end)

    fe_needs_change |> Enum.map(fn(a) ->
      String.split(a.executable_type, ".") |> List.last
      Ecto.Changeset.change(a, executable_type: String.split(a.executable_type, ".") |> List.last)
    end) |> Enum.map(fn(cs) -> repo.update!(cs) end)
    |> fn(updated) ->
      IO.puts "FarmEvents updated: #{Enum.count(updated)}\n\n\n"
    end.()

    point_needs_change = repo.all(from p in Farmbot.Asset.Point)
    |> Enum.filter(fn(asset) ->
      String.contains?(asset.pointer_type, "Repo")
    end)

    point_needs_change |> Enum.map(fn(a) ->
      String.split(a.pointer_type, ".") |> List.last
      Ecto.Changeset.change(a, pointer_type: String.split(a.pointer_type, ".") |> List.last)
    end) |> Enum.map(fn(cs) -> repo.update!(cs) end)
    |> fn(updated) ->
      IO.puts "Points updated: #{Enum.count(updated)}"
    end.()
  end
end
