defmodule FarmbotOS.Asset.Private do
  @moduledoc """
  Private Assets are those that are internal to
  Farmbot that _are not_ stored in the API, but
  _are_ stored in Farmbot's database.
  """
  require Logger
  require FarmbotOS.Logger

  alias FarmbotOS.{Asset.Repo, Asset.Private.LocalMeta}
  alias FarmbotOS.Asset.{FbosConfig, FirmwareConfig}

  import Ecto.Query, warn: false
  import Ecto.Changeset, warn: false

  @doc "Lists `module` objects that still need to be POSTed to the API."
  def list_local(module) do
    Repo.all(from(data in module, where: is_nil(data.id)))
  end

  def list_meta_status(status, module) do
    table = table(module)

    q =
      from(lm in LocalMeta,
        where: lm.table == ^table and lm.status == ^status,
        select: lm.asset_local_id
      )

    Repo.all(from(data in module, join: lm in subquery(q)))
  end

  @doc "Lists `module` objects that have a `local_meta` object"
  def list_dirty(module), do: list_meta_status("dirty", module)

  @doc "Lists `module` objects that have a `local_meta` object"
  def list_stale(module), do: list_meta_status("stale", module)

  @doc "Lists `module` objects that have a `local_meta` object"
  def any_stale?() do
    q =
      from(lm in LocalMeta,
        where: lm.status == "stale",
        select: lm.asset_local_id
      )

    Repo.aggregate(q, :count, :id) != 0
  end

  @doc "Mark a document as `dirty` by creating a `local_meta` object"
  def mark_dirty!(asset, params \\ %{}) do
    set_status!(asset, params, "dirty")
  end

  @doc "Mark a document as `stale` by creating a `local_meta` object"
  def mark_stale!(asset, params \\ %{}) do
    set_status!(asset, params, "stale")
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

  def recover_from_row_lock_failure() do
    (list_dirty(FbosConfig) ++
       list_dirty(FirmwareConfig) ++
       list_stale(FbosConfig) ++
       list_stale(FirmwareConfig))
    |> Enum.map(&mark_clean!/1)
  end

  defp table(%module{}), do: table(module)
  defp table(module), do: module.__schema__(:source)

  defp set_status!(asset, params, status) do
    table = table(asset)

    local_meta =
      Repo.one(
        from(lm in LocalMeta,
          where: lm.asset_local_id == ^asset.local_id and lm.table == ^table
        )
      ) || Ecto.build_assoc(asset, :local_meta)

    ## NOTE(Connor): 19/11/13
    # the try/catch here seems unneeded here, but because of how sqlite/ecto works, it is 100% needed.
    # Because sqlite can't test unique constraints before a transaction, if this function gets called for
    # the same asset more than once asynchronously, the asset can be marked dirty twice at the same time
    # causing the `unique constraint` error to happen in either `ecto` OR `sqlite`. I've
    # caught both errors here as they are both essentially the same thing, and can be safely
    # discarded. Doing an `insert_or_update/1` (without the bang) can still result in the sqlite
    # error being thrown.
    changeset =
      LocalMeta.changeset(
        local_meta,
        Map.merge(params, %{table: table, status: status})
      )

    try do
      Repo.insert_or_update!(changeset)
    catch
      :error,
      %{
        message:
          "UNIQUE constraint failed: local_metas.table, local_metas.asset_local_id"
      } ->
        Logger.warn("""
        Caught race condition marking data as dirty (sqlite)
        table: #{inspect(table)}
        id: #{inspect(asset.local_id)}
        """)

        Ecto.Changeset.apply_changes(changeset)

      :error,
      %Ecto.InvalidChangesetError{
        changeset: %{
          action: :insert,
          errors: [
            table:
              {"LocalMeta already exists.",
               [
                 validation: :unsafe_unique,
                 fields: [:table, :asset_local_id]
               ]}
          ]
        }
      } ->
        Logger.warn("""
        Caught race condition marking data as dirty (ecto)
        table: #{inspect(table)}
        id: #{inspect(asset.local_id)}
        """)

        Ecto.Changeset.apply_changes(changeset)

      type, reason ->
        FarmbotOS.Logger.error(1, """
        Caught unexpected error marking data as dirty
        table: #{inspect(table)}
        id: #{inspect(asset.local_id)}
        error type: #{inspect(type)}
        reason: #{inspect(reason)}
        """)

        Ecto.Changeset.apply_changes(changeset)
    end
  end
end
