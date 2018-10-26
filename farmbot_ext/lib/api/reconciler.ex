defmodule Farmbot.API.Reconciler do
  @moduledoc """
  Handles remote additions and changes.
  """
  require Logger
  alias Ecto.{Changeset, Multi}
  import Ecto.Query

  alias Farmbot.API
  alias Farmbot.Asset.{Repo, Sync}
  alias API.{SyncGroup, EagerLoader}
  import Farmbot.TimeUtils, only: [compare_datetimes: 2]

  @doc """
  Reconcile remote updates. The following steps are wrapped in a tranaction
  that is treated as an `all or nothing` sync.

  * get sync object from API
  * start a new Transaction
    * `sync_group` for groups 1-4, aborting the transaction if there are failures.
  * add the `sync` to the Transaction
  * apply the Transaction.
  """
  def sync do
    # Get the sync changeset
    sync_changeset = API.get_changeset(Sync)
    sync = Changeset.apply_changes(sync_changeset)

    multi = Multi.new()

    with {:ok, multi} <- sync_group(multi, sync, SyncGroup.group_0()),
         {:ok, multi} <- sync_group(multi, sync, SyncGroup.group_1()),
         {:ok, multi} <- sync_group(multi, sync, SyncGroup.group_2()),
         {:ok, multi} <- sync_group(multi, sync, SyncGroup.group_3()),
         {:ok, multi} <- sync_group(multi, sync, SyncGroup.group_4()) do
      Multi.insert(multi, :syncs, sync_changeset)
      |> Repo.transaction()
    end
  end

  @doc """
  Sync a group (list) of modules into a transaction.
  For each item in the `sync` object, belonging to a `module` does the following:

  * checks EagerLoader cache
  * if no cache exists:
    * downloads changeset via HTTP
  * if cache exists:
    * check if cache matches data on the `sync` object
      * if cache is valid: uses cached changeset
      * if cache is _not_ valid, falls back to http
  * applies changeset if there was any changes from cache or http

  """
  def sync_group(multi, sync, [module | rest]) do
    multi
    |> do_sync_group(sync, module)
    |> sync_group(sync, rest)
  end

  def sync_group(multi, _sync, []), do: {:ok, multi}

  defp do_sync_group(multi, sync, module) do
    table = module.__schema__(:source) |> String.to_atom()
    items = Map.fetch!(sync, table)

    ids_fbos_knows_about =
      Repo.all(from(d in module, where: not is_nil(d.id), select: d.id))
      |> Enum.sort()

    ids_the_api_knows_about =
      Enum.map(items, &Map.fetch!(&1, :id))
      |> Enum.sort()

    ids_that_were_deleted = ids_fbos_knows_about -- ids_the_api_knows_about

    multi =
      Enum.reduce(ids_that_were_deleted, multi, fn id, multi ->
        Logger.info("delete: #{module} #{inspect(id)}")
        local_item = Repo.one!(from(d in module, where: d.id == ^id))
        Multi.delete(multi, {table, id}, local_item)
      end)

    # TODO(Connor) make this reduce async with Task/Agent
    Enum.reduce(items, multi, &multi_reduce(module, table, &1, &2))
  end

  @doc false
  def multi_reduce(module, table, item, multi) do
    cached_cs = EagerLoader.get_cache(module, item.id)
    local_item = Repo.one(from(d in module, where: d.id == ^item.id))

    case get_changeset(local_item || module, item, cached_cs) do
      {:insert, %Changeset{} = cs} ->
        Logger.info("insert: #{inspect(cs)}")
        Multi.insert(multi, {table, item.id}, cs)

      {:update, %Changeset{} = cs} ->
        Logger.info("update: #{inspect(cs)}")
        Multi.update(multi, {table, item.id}, cs)

      nil ->
        Logger.info("Local data: #{local_item.__struct__} is current.")
        multi
    end
  end

  defp get_changeset(local_item, sync_item, cached_cs)

  # A module is passed in if there is no local copy of the data.
  defp get_changeset(module, sync_item, nil) when is_atom(module) do
    Logger.info("Local data: #{module} does not exist. Using HTTP to get data.")
    {:insert, API.get_changeset(module, "#{sync_item.id}")}
  end

  defp get_changeset(module, sync_item, %Changeset{} = cached) when is_atom(module) do
    cached_updated_at = Changeset.get_field(cached, :updated_at)

    if compare_datetimes(sync_item.updated_at, cached_updated_at) == :eq do
      {:insert, cached}
    else
      Logger.info("Cached item is out of date")
      get_changeset(module, sync_item, nil)
    end
  end

  # no cache available
  # If the `sync_item.updated_at` is newer than `local_item.updated_at`
  # HTTP get the data.
  defp get_changeset(%{} = local_item, sync_item, nil) do
    # Check if remote data is newer
    if compare_datetimes(sync_item.updated_at, local_item.updated_at) == :gt do
      raise("#{inspect(local_item)} #{sync_item.updated_at} :gt #{local_item.updated_at}")

      Logger.info(
        "Local data: #{local_item.__struct__} is out of date. Using HTTP to get newer data."
      )

      {:update, API.get_changeset(local_item, "#{sync_item.id}")}
    end
  end

  # We have a cache.
  # First check if it is the same `updated_at` as what the API has.
  # If the cache is the same `updated_at` as the API, check if the cache
  # is newer than `local_item.updated_at`
  # if the cache is not the same `updated_at` as the API, fallback to HTTP.
  defp get_changeset(%{} = local_item, sync_item, %Changeset{} = cached) do
    cached_updated_at = Changeset.get_field(cached, :updated_at)

    if compare_datetimes(sync_item.updated_at, cached_updated_at) == :eq do
      if compare_datetimes(cached_updated_at, local_item.updated_at) == :gt do
        Logger.info(
          "Local data: #{local_item.__struct__} is out of date. Using cache do get newer data."
        )

        {:update, cached}
      end
    else
      Logger.info("Cached item is out of date")
      get_changeset(local_item, sync_item, nil)
    end
  end
end
