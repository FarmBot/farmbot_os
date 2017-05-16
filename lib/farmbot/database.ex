defmodule Farmbot.Database do
  @moduledoc """
    Database Implementation.
  """

  use GenServer
  use Farmbot.DebugLog
  require Logger
  alias Farmbot.Database.Syncable

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
  @type resource_map :: Farmbot.Database.Syncable.t

  @typedoc false
  @type verb :: Farmbot.CeleryScript.Command.DataUpdate.verb

  @typedoc """
    State of the DB
  """
  @type state :: %{
    all: [ref_id],

    by_kind: %{
      required(syncable) => [ref_id]
    },

    by_kind_and_id: %{
      required({syncable, db_id}) => ref_id
    },

    refs: %{
      required(ref_id) => resource_map
    },

    awaiting: %{
      add:    [ref_id],
      remove: [ref_id],
      update: [ref_id]
    }
  }

  # This pulls all the module names by their filename.
  syncable_modules =
    "lib/farmbot/database/syncable/"
    |> File.ls!
    |> Enum.map(fn(file_name) ->
         mod_name_str = String.trim(file_name, ".ex")
         mod_name     = Macro.camelize(mod_name_str)
         Module.concat([Farmbot.Database.Syncable, mod_name])
    end)

  @doc """
    All the tags that the Database knows about.
  """
  def all_the_syncables do
    unquote(syncable_modules)
  end

  @doc """
    Sync up with the API.
  """
  def sync do
    for module_name <- all_the_syncables() do
      # see: `syncable.ex`. This is some macro magic.
      module_name.fetch({__MODULE__, :commit_records, [module_name]})
    end
  end

  @doc """
    Commits a list of records to the db.
  """
  def commit_records(list_or_single_record, module_name)
  def commit_records([record | rest], mod_name) do
    debug_log "Staring db commit with: #{mod_name}"
    commit_records(record, mod_name)
    commit_records(rest, mod_name)
  end

  def commit_records([], mod_name) do
    debug_log "DB commit finish: #{mod_name}"
    :ok
  end

  def commit_records(record, _mod_name) when is_map(record) do
    GenServer.call(__MODULE__, {:update_or_create, record})
  end

  def commit_records({:error, reason}, mod_name) do
    Logger.error("#{mod_name}: #{inspect reason}")
    {:error, reason}
  end

  @doc """
    Sets awaiting api resources.
  """
  def set_awaiting(syncable, verb, value) do
    debug_log("setting awaiting: #{syncable} #{verb}")
    GenServer.call(__MODULE__, {:set_awaiting, syncable, verb, value})
  end

  @doc """
    Gets the awaiting api recources for syncable and verb
  """
  def get_awaiting(syncable, verb) do
    GenServer.call(__MODULE__, {:get_awaiting, syncable, verb})
  end

  @doc """
    Get a resource by its kind and id.
  """
  @spec get_by_id(syncable, db_id) :: resource_map | nil
  def get_by_id(kind, id), do: GenServer.call(__MODULE__, {:get_by, kind, id})

  @doc """
    Get all resources of this kind.
  """
  @spec get_all(syncable) :: [resource_map]
  def get_all(kind), do: GenServer.call(__MODULE__, {:get_all, kind})

  ## GenServer

  @doc """
    Start the Database
  """
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    state = %{
      all: [],
      by_kind: generate_keys(all_the_syncables()),
      by_kind_and_id: %{},
      awaiting: generate_keys([:add, :remove, :update]),
      refs: %{}
    }
    {:ok, state}
  end

  defp generate_keys(keys) do
    keys
    |> Enum.map(fn(key) -> {key, []} end)
    |> Map.new
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

  def handle_call({:get_awaiting, module, verb}, _, state) do
    r =
      Enum.filter(state.awaiting[verb], fn(ref) ->
        item = Map.fetch!(state.refs, ref)
        item.body.__struct__ != module
      end)
    {:reply, r, state}
  end

  # wildcard is easy
  # TODO(Rick): Not the right idea. "*" will need to do a force re-sync.
  #             All resource of type "syncable".
  def handle_call({:set_awaiting, syncable, verb, "*"}, _, state) do
    raise "Not yet implemented."
  end

  def handle_call({:set_awaiting, syncable, :add, id}, _, state) do
    ref           = new_ref_id(syncable, id)
    next_awaiting = %{state.awaiting | add: [ref | state.awaiting.add]}
    next_state    = %{state | awaiting: next_awaiting}
    {:no_reply, :ok, next_state}
  end

  def handle_call({:set_awaiting, syncable, verb, id}, _, state) do
    # get the reference by its kind and id.

    item = get_by_kind_and_id(state, syncable, id) || raise "#{syncable} num" <>
      "ber #{ id } not found."

    # old list of things that were out dated
    old_by_verb = state.awaiting[verb]

    # new list
    new_by_verb = [item.ref_id | old_by_verb]

    # update the verb with new info from above.
    new_awaiting = %{state.awaiting | verb => new_by_verb}

    new_state = %{state | awaiting: new_awaiting}
    {:reply, :ok, new_state}
  end

  # returns all the references of syncable
  @spec get_all_by_kind(state, syncable) :: [resource_map]
  defp get_all_by_kind(state, syncable) do
    all = state.by_kind[syncable]
    if all do
      Enum.map(all, fn(ref) -> state.refs[ref] end)
    else
      []
    end
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

  @spec new_ref_id(syncable, integer) :: ref_id
  defp new_ref_id(syncable, id) do
    # TODO(Connor) One day, we will need a local id.
    {syncable, -1, id}
  end

  defp reindex(state, record) do
    # get some info
    kind = Map.get(record, :__struct__)
    id = Map.fetch!(record, :id)

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
      by_kind        = %{ state.by_kind | kind => [rid | state.by_kind[kind]] }
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
