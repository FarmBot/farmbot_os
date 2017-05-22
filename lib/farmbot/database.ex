defmodule Farmbot.Database do
  @moduledoc """
    Database Implementation.
  """

  alias Farmbot.Database.Syncable
  alias Farmbot.Context
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
  @type resource_map :: Farmbot.Database.Syncable.t

  @typedoc false
  @type verb :: Farmbot.CeleryScript.Command.DataUpdate.verb

  @typedoc false
  @type db :: pid

  @typedoc false
  @type syncable_object :: map

  @typedoc """
    State of the DB
  """
  @type state :: %{
    by_kind_and_id: %{ required({syncable, db_id}) => ref_id       },
    awaiting:       %{ required(syncable)          => boolean      },
    by_kind:        %{ required(syncable)          => [ref_id]     },
    refs:           %{ required(ref_id)            => resource_map },
    all:            [ref_id],
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
  @spec all_syncable_modules :: [syncable]
  def all_syncable_modules, do: unquote(syncable_modules)

  @doc """
    Sync up with the API.
  """
  @spec sync(Context.t) :: :ok | no_return
  def sync(%Context{} = ctx) do
    Farmbot.BotState.set_sync_msg(ctx, :syncing)
    try do
      for module_name <- all_syncable_modules() do
        # see: `syncable.ex`. This is some macro magic.
        debug_log "#{module_name} Sync begin."
        :ok = module_name.fetch({__MODULE__,
          :commit_records,  [ctx, module_name]})

        debug_log "#{module_name} Sync finish."
        :ok
      end
      Farmbot.BotState.set_sync_msg(ctx, :synced)
      :ok
    rescue
      e ->
        Logger.info ">> Encountered error syncing, #{inspect e}", type: :error
        Farmbot.BotState.set_sync_msg(ctx, :sync_error)
    end
  end

  @doc """
    Commits a list of records to the db.
  """
  @spec commit_records([map] | map, Context.t, syncable) :: :ok | {:error, term}
  def commit_records(list_or_single_record, context, module_name)
  def commit_records([record | rest], %Context{} = ctx, mod_name) do
    debug_log "DB commit start: [#{mod_name}]"
    commit_records(record, ctx, mod_name)
    commit_records(rest, ctx, mod_name)
  end

  def commit_records([], %Context{} = _ctx, mod_name) do
    debug_log "DB commit finish: [#{mod_name}]"
    :ok
  end

  def commit_records(record, %Context{} = ctx, mod_name) when is_map(record) do
    debug_log "DB doing commit_record [#{mod_name}]"
    GenServer.call(ctx.database, {:update_or_create, record})
  end

  def commit_records({:error, reason}, _context, mod_name) do
    Logger.error("#{mod_name}: #{inspect reason}")
    {:error, reason}
  end

  @doc """
    Clear the entire DB
  """
  def flush(%Context{} = ctx), do: GenServer.call(ctx.database, :flush)

  @doc """
    Sets awaiting api resources.
  """
  @spec set_awaiting(Context.t, syncable, verb, any) :: :ok | no_return
  def set_awaiting(%Context{database: db}, syncable, verb, value) do
    debug_log("setting awaiting: #{syncable} #{verb}")
    GenServer.call(db, {:set_awaiting, syncable, verb, value})
  end

  @doc """
    Unsets awaiting api resources.
  """
  @spec unset_awaiting(Context.t, syncable) :: :ok | no_return
  def unset_awaiting(%Context{database: db}, syncable),
    do: GenServer.call(db, {:unset_awaiting, syncable})

  @doc """
    Gets the awaiting api recources for syncable and verb
  """
  @spec get_awaiting(Context.t, syncable) :: boolean
  def get_awaiting(%Context{database: db}, syncable) do
    GenServer.call(db, {:get_awaiting, syncable})
  end

  @doc """
    Get a resource by its kind and id.
  """
  @spec get_by_id(Context.t, syncable, db_id) :: resource_map | nil
  def get_by_id(%Context{database: db}, kind, id), do: GenServer.call(db, {:get_by, kind, id})

  @doc """
    Get all resources of this kind.
  """
  @spec get_all(Context.t, syncable) :: [resource_map]
  def get_all(%Context{database: db}, kind), do: GenServer.call(db, {:get_all, kind})

  ## GenServer

  @doc """
    Start the Database
  """
  def start_link(_context, opts), do: GenServer.start_link(__MODULE__, [], opts)

  def init([]) do
    initial_by_kind_and_id = %{}
    initial_awaiting       = generate_keys(all_syncable_modules(), true)
    initial_by_kind        = generate_keys(all_syncable_modules())
    initial_refs           = %{}
    initial_all            = []

    state = %{
      by_kind_and_id: initial_by_kind_and_id,
      awaiting:       initial_awaiting,
      by_kind:        initial_by_kind,
      refs:           initial_refs,
      all:            initial_all,
    }
    {:ok, state}
  end

  defp generate_keys(keys, default \\ []) do
    keys
    |> Enum.map(fn(key) -> {key, default} end)
    |> Map.new
  end

  def handle_call(:flush, _, _state) do
    {:ok, state} = init([])
    {:reply, :ok, state}
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

  def handle_call({:get_awaiting, module}, _, state) do
    {:reply, Map.fetch!(state.awaiting, module), state}
  end

  def handle_call({:set_awaiting, syncable, _verb, _}, _, state) do
    {:reply, :ok, %{ state | awaiting: %{ state.awaiting | syncable => true} }}
  end

  def handle_call({:unset_awaiting, syncable}, _, state) do
    {:reply, :ok, %{ state | awaiting: %{ state.awaiting | syncable => false} }}
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

  defp reindex(state, record) do
    # get some info
    kind = Map.fetch!(record, :__struct__)
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
