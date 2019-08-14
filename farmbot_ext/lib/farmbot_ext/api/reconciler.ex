defmodule FarmbotExt.API.Reconciler do
  @moduledoc """
  Handles remote additions and changes.
  """
  require Logger
  alias Ecto.Changeset
  import Ecto.Query

  alias FarmbotExt.API
  alias API.{SyncGroup, EagerLoader}

  alias FarmbotCore.Asset.{Command, Repo, Sync, Sync.Item}
  import FarmbotCore.TimeUtils, only: [compare_datetimes: 2]

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
    with {:ok, sync_changeset} <- API.get_changeset(Sync),
         %Changeset{valid?: true} = sync_changeset <-
           sync_group(sync_changeset, SyncGroup.group_0()),
         %Changeset{valid?: true} = sync_changeset <-
           sync_group(sync_changeset, SyncGroup.group_1()),
         %Changeset{valid?: true} = sync_changeset <-
           sync_group(sync_changeset, SyncGroup.group_2()),
         %Changeset{valid?: true} = sync_changeset <-
           sync_group(sync_changeset, SyncGroup.group_3()),
         %Changeset{valid?: true} <- sync_group(sync_changeset, SyncGroup.group_4()) do
      :ok
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
  def sync_group(%Changeset{} = sync_changeset, [module | rest]) do
    with sync_changeset <- do_sync_group(sync_changeset, module) do
      sync_group(sync_changeset, rest)
    end
  end

  def sync_group(%Changeset{valid?: true} = ok, []), do: ok
  def sync_group(%Changeset{valid?: false} = error, []), do: {:error, error}

  defp do_sync_group(%Changeset{} = sync_changeset, module) when is_atom(module) do
    table = module.__schema__(:source) |> String.to_atom()
    # items is a list of changesets
    items = Changeset.get_field(sync_changeset, table)
    items || raise("Could not find #{table} in sync")

    # TODO(Connor) maybe move this into Asset.Query
    ids_fbos_knows_about =
      Repo.all(from(d in module, where: not is_nil(d.id), select: d.id))
      |> Enum.sort()

    ids_the_api_knows_about =
      Enum.map(items, &Map.fetch!(&1, :id))
      |> Enum.sort()

    ids_that_were_deleted = ids_fbos_knows_about -- ids_the_api_knows_about

    sync_changeset =
      Enum.reduce(ids_that_were_deleted, sync_changeset, fn id, sync_changeset ->
        Logger.info("delete: #{module} #{inspect(id)}")
        Command.update(module, id, nil)
        sync_changeset
      end)

    # TODO(Connor) make this reduce async with Task/Agent
    Enum.reduce(items, sync_changeset, &sync_reduce(module, &1, &2))
  end

  @doc false
  def sync_reduce(module, %Item{} = item, %Changeset{} = sync_changeset) when is_atom(module) do
    cached_cs = EagerLoader.get_cache(module, item.id)
    local_item = Repo.one(from(d in module, where: d.id == ^item.id))

    case get_changeset(local_item || module, item, cached_cs) do
      {:insert, %Changeset{} = cs} ->
        Logger.info("insert: #{inspect(cs)}")
        item = module.render(Changeset.apply_changes(cs))
        :ok = Command.update(module, item.id, item)
        sync_changeset

      {:update, %Changeset{} = cs} ->
        Logger.info("update: #{inspect(cs)}")
        item = module.render(Changeset.apply_changes(cs))
        :ok = Command.update(module, item.id, item)
        sync_changeset

      nil ->
        Logger.info("Local data: #{local_item.__struct__} is current.")
        sync_changeset
    end
  end

  defp get_changeset(local_item, sync_item, cached_changeset)

  # A module is passed in if there is no local copy of the data.
  defp get_changeset(module, %Item{} = sync_item, nil) when is_atom(module) do
    Logger.info("Local data: #{module} does not exist. Using HTTP to get data.")
    {:ok, changeset} = API.get_changeset(module, "#{sync_item.id}")
    {:insert, changeset}
  end

  defp get_changeset(module, %Item{} = sync_item, %Changeset{} = cached) when is_atom(module) do
    cached_updated_at = Changeset.get_field(cached, :updated_at)
    sync_item_updated_at = sync_item.updated_at

    if compare_datetimes(sync_item_updated_at, cached_updated_at) == :eq do
      {:insert, cached}
    else
      Logger.info("Cached item is out of date")
      get_changeset(module, sync_item, nil)
    end
  end

  # no cache available
  # If the `sync_item.updated_at` is newer than `local_item.updated_at`
  # HTTP get the data.
  defp get_changeset(%{} = local_item, %Item{} = sync_item, nil) do
    sync_item_updated_at = sync_item.updated_at
    sync_item_id = sync_item.id

    # Check if remote data is newer
    if compare_datetimes(sync_item_updated_at, local_item.updated_at) == :gt do
      Logger.info(
        "Local data: #{local_item.__struct__} is out of date. Using HTTP to get newer data."
      )

      {:ok, changeset} = API.get_changeset(local_item, "#{sync_item_id}")
      {:update, changeset}
    end
  end

  # We have a cache.
  # First check if it is the same `updated_at` as what the API has.
  # If the cache is the same `updated_at` as the API, check if the cache
  # is newer than `local_item.updated_at`
  # if the cache is not the same `updated_at` as the API, fallback to HTTP.
  defp get_changeset(%{} = local_item, %Item{} = sync_item, %Changeset{} = cached) do
    cached_updated_at = Changeset.get_field(cached, :updated_at)
    sync_item_updated_at = sync_item.updated_at
    cache_compare = compare_datetimes(sync_item_updated_at, cached_updated_at)

    if cache_compare == :eq || cache_compare == :gt do
      Logger.info(
        "Local data: #{local_item.__struct__} is out of date. Using cache do get newer data."
      )

      {:update, cached}
    else
      Logger.info("Cached item is out of date")
      get_changeset(local_item, sync_item, nil)
    end
  end
end
