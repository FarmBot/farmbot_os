defmodule Farmbot.Database.RecordStorage do
  @moduledoc """
  This module is only responsible for storage of information.
  """

  alias Farmbot.Database.Syncable
  use Farmbot.DebugLog, color: :LIGHT_PURPLE
  require Logger
  use GenServer

  @typedoc """
  The module name of the object you want to access.
  """
  @type syncable :: atom

  @typedoc """
  The incremental id givin to resources.
  """
  @type local_id :: integer

  @typedoc """
  The (API) Database id given to resources.
  """
  @type db_id :: integer

  @typedoc """
  Identifies a resource by its `syncable` (kind), `local_id`, and `db_id`
  """
  @type ref_id :: {syncable, local_id, db_id}

  @typedoc """
  Held in `refs`.
  """
  @type resource_map :: Syncable.t

  @typedoc false
  @type record_storage :: GenServer.server

  @typedoc false
  @type syncable_object :: map

  @doc """
  Commits a list of records to the db.
  """
  @spec commit_records([map] | map, record_storage) :: :ok | {:error, term}
  def commit_records(list_or_single_record, record_storage)

  def commit_records([record | rest], record_storage) do
    :ok = commit_records(record, record_storage)
    commit_records(rest, record_storage)
  end

  def commit_records([], _record_storage) do
    :ok
  end

  def commit_records(record, record_storage) when is_map(record) do
    :ok = GenServer.call(record_storage, {:update_or_create, record})
  end

  @doc "Clear all records."
  def flush(record_storage), do: GenServer.call(record_storage, :flush)

  @doc "Flush a syncable."
  def flush(record_storage, syncable), do: GenServer.call(record_storage, {:flush, syncable})

  @doc """
  Get a resource by its kind and id.
  """
  @spec get_by_id(record_storage, syncable, db_id) :: resource_map | nil
  def get_by_id(record_storage, kind, id),
    do: GenServer.call(record_storage, {:get_by, kind, id})

  @doc """
  Get all resources of this kind.
  """
  @spec get_all(record_storage, syncable) :: [resource_map]
  def get_all(record_storage, kind),
    do: GenServer.call(record_storage, {:get_all, kind})

  ## GenServer

  defmodule State do
    @moduledoc false

    defimpl Inspect, for: __MODULE__ do
      def inspect(thing, _) do
        "#DatabaseState<#{inspect thing.all}>"
      end
    end

    defstruct [
      :by_kind_and_id,
      :awaiting,
      :by_kind,
      :refs,
      :all
    ]
  end

  @typep state :: State.t

  @doc """
  Start the Database
  """
  def start_link(opts),
    do: GenServer.start_link(__MODULE__, [], opts)

  def init([]) do
    initial_by_kind_and_id = %{}
    initial_by_kind        = %{}
    initial_refs           = %{}
    initial_all            = []

    state = %State{
      by_kind_and_id: initial_by_kind_and_id,
      by_kind:        initial_by_kind,
      refs:           initial_refs,
      all:            initial_all,
    }
    {:ok, state}
  end

  def handle_call(:flush, _, _old_state) do
    {:ok, new_state} = init([])
    {:reply, :ok, new_state}
  end

  def handle_call({:flush, syncable}, _, old_state) do
    {:reply, :ok, remove_all_syncable(old_state, syncable)}
  end

  def handle_call({:get_by, kind, id}, _, state) do
    r = get_by_kind_and_id(state, kind, id)
    {:reply, r, state}
  end

  def handle_call({:get_all, syncable}, _, state) do
    {:reply, get_all_by_kind(state, syncable), state}
  end

  def handle_call({:update_or_create, record}, _, state) do
    {:reply, :ok, reindex(state, record)}
  end

  @spec remove_all_syncable(state, syncable) :: state
  defp remove_all_syncable(state, syncable) do
    new_all = Enum.reject(state.all, fn({s, _, _}) -> s == syncable end)

    new_by_kind_and_id = state.by_kind_and_id
      |> Enum.reject(fn({{s, _}, _}) -> s == syncable end)
      |> Map.new

    new_refs = state.refs
      |> Enum.reject(fn({{s, _, _}, _}) -> s == syncable end)
      |> Map.new()

    %{
      state |
      by_kind_and_id: new_by_kind_and_id,
      by_kind:        Map.put(state.by_kind, syncable, []),
      refs:           new_refs,
      all:            new_all
     }
  end

  # returns all the references of syncable
  @spec get_all_by_kind(state, syncable) :: [resource_map]
  defp get_all_by_kind(state, syncable) do
    all = state.by_kind[syncable] || []
    Enum.map(all, fn(ref) -> state.refs[ref] end)
  end

  @spec get_by_kind_and_id(state, syncable, integer) :: resource_map | nil
  defp get_by_kind_and_id(state, kind, id) do
    case state.by_kind_and_id[{kind, id}] do
      {_kind, _local_id, db_id} = ref when id == db_id ->
        state.refs[ref]
      _ -> nil
    end
  end

  @spec new_ref_id(map) :: ref_id
  defp new_ref_id(%{__struct__: syncable, id: id}) do
    # TODO(Connor) One day, we will need a local id.
    {syncable, -1, id}
  end

  defp reindex(state, record) do
    # get some info
    kind = Map.fetch!(record, :__struct__)
    id   = Map.fetch!(record, :id) || raise "No id for record: #{inspect record}"

    # Do we have it already?
    maybe_old = get_by_kind_and_id(state, kind, id)
    if maybe_old do
      debug_log("updating old record")
      already_exists = maybe_old
      # if it existed, update it.
      # set the ref from the old one.
      new = %{already_exists | body: record}
      new_refs = %{state.refs | new.ref_id => new}
      %{state | refs: new_refs}
    else
      debug_log("inputting new record")
      # if not, just add it.
      rid =  new_ref_id(record)

      new_syncable = %Syncable{
        body: record,
        ref_id: rid
      }

      all            = [rid | state.all]
      by_kind        = Map.put(state.by_kind, kind, [rid | state.by_kind[kind] || []])
      new_refs       = Map.put(state.refs, rid, new_syncable)
      by_kind_and_id = Map.put(state.by_kind_and_id, {kind, id}, rid)

      %{ state |
         refs:           new_refs,
         all:            all,
         by_kind:        by_kind,
         by_kind_and_id: by_kind_and_id }
    end
  end
end
