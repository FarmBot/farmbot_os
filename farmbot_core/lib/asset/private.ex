defmodule Farmbot.Asset.Private do
  alias Farmbot.Asset.Repo
  alias Farmbot.Asset.Private.LocalMeta

  import Ecto.Query, warn: false
  import Ecto.Changeset, warn: false

  @doc "Lists `module` objects that still need to be POSTed to the API."
  def list_local(module) do
    Repo.all(from(data in module, where: is_nil(data.id)))
  end

  @doc "Lists `module` objects that have a `local_meta` object"
  def list_dirty(module) do
    table = table(module)
    q = from(lm in LocalMeta, where: lm.table == ^table, select: lm.asset_local_id)
    Repo.all(from(data in module, join: lm in subquery(q)))
  end

  @doc "Mark a document as `dirty` by creating a `local_meta` object"
  def mark_dirty!(asset, params) do
    table = table(asset)

    local_meta =
      Repo.one(
        from(lm in LocalMeta, where: lm.asset_local_id == ^asset.local_id and lm.table == ^table)
      ) || Ecto.build_assoc(asset, :local_meta)

    local_meta
    |> LocalMeta.changeset(Map.merge(params, %{table: table, status: "dirty"}))
    |> Repo.insert_or_update!()
  end

  @doc "Remove the `local_meta` record from an object."
  @spec mark_clean!(map) :: nil | map()
  def mark_clean!(data) do
    Repo.preload(data, :local_meta)
    |> Map.fetch!(:local_meta)
    |> case do
      nil -> nil
      local_meta -> Repo.delete!(local_meta)
    end
  end

  defp table(%module{}), do: table(module)
  defp table(module), do: module.__schema__(:source)
end
