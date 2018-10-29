defmodule Farmbot.API.EagerLoader do
  @moduledoc "Handles caching of asset changes"
  alias Farmbot.API
  alias API.{SyncGroup, EagerLoader}
  alias Farmbot.Asset.{Repo, Sync}
  alias Ecto.Changeset
  import Ecto.Query
  require Logger
  use GenServer

  @doc "Does a ton of HTTP requests to preload the cache"
  def preload do
    sync = API.get_changeset(Sync) |> Changeset.apply_changes()

    SyncGroup.all_groups()
    |> Enum.map(fn asset_module ->
      table = asset_module.__schema__(:source) |> String.to_existing_atom()
      {asset_module, Map.fetch!(sync, table)}
    end)
    |> Enum.map(fn {asset_module, sync_items} ->
      Enum.map(sync_items, fn sync_item ->
        Task.async(__MODULE__, :preload, [asset_module, sync_item])
      end)
    end)
    |> List.flatten()
    |> Enum.map(&Task.await(&1, :infinity))

    :ok
  end

  def preload(asset_module, %{id: id}) when is_atom(asset_module) do
    local = Repo.one(from(m in asset_module, where: m.id == ^id)) || asset_module
    :ok = API.get_changeset(local, id) |> cache()
  end

  @doc "Get a Changeset by module and id. May return nil"
  def get_cache(module, id) do
    pid(module)
    |> GenServer.call({:get_cache, id})
  end

  @doc "Don't use this in production"
  def inspect_cache(module) do
    pid(module)
    |> GenServer.call(:get_cache)
  end

  @doc """
  Cache a Changeset.
  This Changeset _must_ be complete. This includes:
    * Existing data if this is an update
    * a remote `id` field.
  """
  def cache(%Changeset{data: %module{}} = changeset) do
    id = Changeset.get_field(changeset, :id)
    updated_at = Changeset.get_field(changeset, :updated_at)
    id || change_error(changeset, "Can't cache a changeset with no :id attribute")
    updated_at || change_error(changeset, "Can't cache a changeset with no :updated_at attribute")

    pid(module)
    |> GenServer.cast({:cache, id, changeset})
  end

  defp change_error(changeset, message) do
    raise(Ecto.ChangeError, message: message <> ": #{inspect(changeset)}")
  end

  defp pid(module) do
    Supervisor.which_children(EagerLoader.Supervisor)
    |> Enum.find_value(fn {{EagerLoader, child_module}, pid, :worker, _} ->
      module == child_module && pid
    end)
  end

  @doc false
  def child_spec(module) when is_atom(module) do
    %{
      id: {EagerLoader, module},
      start: {__MODULE__, :start_link, [[module: module]]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    module = Keyword.fetch!(args, :module)
    {:ok, %{module: module, cache: %{}}}
  end

  def handle_cast({:cache, id, changeset}, state) do
    {:noreply, %{state | cache: Map.put(state.cache, id, changeset)}}
  end

  def handle_call({:get_cache, id}, _, state) do
    {result, cache} = Map.pop(state.cache, id)
    {:reply, result, %{state | cache: cache}}
  end

  def handle_call(:get_cache, _, state) do
    {:reply, state.cache, state}
  end
end
