defmodule FarmbotOS.API.Reconciler do
  @moduledoc """
  Handles additions, deletions and changes of remote API resources

  Uses the `updated_at` and `created_at` common fields of api resources
  to determine if FarmbotOS or the API's resource is more current
  """

  require Logger
  alias Ecto.Changeset
  import Ecto.Query

  alias FarmbotOS.{API, EagerLoader}
  alias API.SyncGroup

  alias FarmbotOS.Asset.{Command, Repo, Sync, Sync.Item}
  import FarmbotOS.TimeUtils, only: [compare_datetimes: 2]

  @doc """
  Reconcile remote updates. The following steps are wrapped in a transaction
  that is treated as an `all or nothing` sync.

  * get sync object from API
  * start a new Transaction
    * `sync_group` for groups 1-4, aborting the transaction if there are failures.
  * add the `sync` to the Transaction
  * apply the Transaction.
  """
  def sync do
    with {:ok, sc} <- API.get_changeset(Sync),
         %Changeset{valid?: true} = sc <- sync_group(sc, SyncGroup.group_0()),
         %Changeset{valid?: true} = sc <- sync_group(sc, SyncGroup.group_1()),
         %Changeset{valid?: true} = sc <- sync_group(sc, SyncGroup.group_2()),
         %Changeset{valid?: true} = sc <- sync_group(sc, SyncGroup.group_3()),
         %Changeset{valid?: true} <- sync_group(sc, SyncGroup.group_4()) do
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

  defp do_sync_group(%Changeset{} = sync_changeset, module)
       when is_atom(module) do
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
      Enum.reduce(ids_that_were_deleted, sync_changeset, fn id,
                                                            sync_changeset ->
        Command.update(module, id, nil)
        sync_changeset
      end)

    Enum.reduce(items, sync_changeset, &sync_reduce(module, &1, &2))
  end

  @doc false
  def sync_reduce(module, %Item{} = item, %Changeset{} = sync_changeset)
      when is_atom(module) do
    cached_cs = EagerLoader.get_cache(module, item.id)
    local_item = Repo.one(from(d in module, where: d.id == ^item.id))

    case get_changeset(local_item || module, item, cached_cs) do
      {:insert, %Changeset{} = cs} -> handle_change(module, cs)
      {:update, %Changeset{} = cs} -> handle_change(module, cs)
      nil -> nil
    end

    sync_changeset
  end

  defp handle_change(module, cs) do
    item = module.render(Changeset.apply_changes(cs))
    :ok = Command.update(module, item.id, item)
  end

  defp get_changeset(local_item, sync_item, cached_changeset)

  # A module is passed in if there is no local copy of the data.
  defp get_changeset(module, %Item{} = sync_item, nil) when is_atom(module) do
    {:ok, changeset} = API.get_changeset(module, "#{sync_item.id}")
    {:insert, changeset}
  end

  defp get_changeset(module, %Item{} = sync_item, %Changeset{} = cached)
       when is_atom(module) do
    cached_updated_at = Changeset.get_field(cached, :updated_at)
    sync_item_updated_at = sync_item.updated_at

    if compare_datetimes(sync_item_updated_at, cached_updated_at) == :eq do
      {:insert, cached}
    else
      # Logger.info("Cached item is out of date")
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
      result = API.get_changeset(local_item, "#{sync_item_id}")

      case result do
        {:ok, changeset} ->
          {:update, changeset}

        other ->
          msg = "Can't get changeset: #{inspect(other)}"
          Logger.info(msg)
          nil
      end
    end
  end

  # We have a cache.
  # First check if it is the same `updated_at` as what the API has.
  # If the cache is the same `updated_at` as the API, check if the cache
  # is newer than `local_item.updated_at`
  # if the cache is not the same `updated_at` as the API, fallback to HTTP.
  defp get_changeset(
         %{} = local_item,
         %Item{} = sync_item,
         %Changeset{} = cached
       ) do
    cached_updated_at = Changeset.get_field(cached, :updated_at)
    sync_item_updated_at = sync_item.updated_at
    cache_compare = compare_datetimes(sync_item_updated_at, cached_updated_at)

    if cache_compare == :eq || cache_compare == :gt do
      # Logger.info(
      #   "Local data: #{local_item.__struct__} is out of date. Using cache do get newer data."
      # )

      {:update, cached}
    else
      # Logger.info("Cached item is out of date")
      get_changeset(local_item, sync_item, nil)
    end
  end
end
