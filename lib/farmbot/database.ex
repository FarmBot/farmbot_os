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

  defp set_syncing(ctx, msg) do
    :ok = Farmbot.BotState.set_sync_msg(ctx, msg)
    :ok
  end

  defp broadcast_sync(%Context{database: db}, msg),
    do: GenServer.cast(db, {:broadcast_sync, msg})

  @doc """
    Sync up with the API.
  """
  @spec sync(Context.t) :: :ok | no_return
  def sync(%Context{} = ctx) do
    unless syncing?(ctx) do
      set_syncing(ctx,    :syncing)
      broadcast_sync(ctx, :sync_start)

      all     = all_syncable_modules()
      tasks   = Enum.map(all, fn(module) ->
        Task.async(__MODULE__, :sync_module, [ctx, module, 0])
      end)

      results = Enum.partition(tasks, fn(task) ->
        Task.await(task) == :ok
      end)

      handle_sync_results(ctx, results)
      broadcast_sync(ctx, :sync_end)
    end
    :ok
  end

  defp handle_sync_results(%Context{} = ctx, {_, []}) do
    set_syncing(ctx, :synced)
    Logger.info ">> is synced.", type: :success
    :ok
  end

  defp handle_sync_results(%Context{} = ctx, {_, _}) do
    set_syncing(ctx, :sync_error)
    Logger.info ">> encountered errors syncing.", type: :error
    :ok
  end

  @doc """
    Sync a particular module
  """
  def sync_module(context, module_name, retries \\ 0)
  def sync_module(%Context{} = ctx, module_name, retries) when retries > 4 do
    debug_log "#{module_name} failed to sync too many times. (#{retries})"
    Logger.error ">> failed to sync #{module_name |> human_readable_module()} to many times."
    set_syncing(ctx,    :sync_error)
    broadcast_sync(ctx, :sync_error)
    :error
  end

  def sync_module(%Context{} = ctx, module_name, retries) do
    # see: `syncable.ex`. This is some macro magic.
    # debug_log "#{module_name} Sync begin."
    Logger.debug(">> is syncing: #{module_name |> human_readable_module()}", type: :busy)

    if get_awaiting(ctx, module_name) do
      try do
        :ok = module_name.fetch(ctx, {__MODULE__,
        :commit_records,  [ctx, module_name]})

        # debug_log "#{module_name} Sync finish."
        Logger.debug(">> synced: #{module_name |> human_readable_module()}", type: :success)
        :ok = unset_awaiting(ctx, module_name)
        :ok
      rescue
        e ->
          # debug_log "#{module_name} Sync error: #{inspect e}"
          IO.warn "#{module_name} HEY LOOK AT ME: #{inspect e}"
          Logger.warn("Retrying sync: #{module_name |> human_readable_module()}")
          sync_module(ctx, module_name, retries + 1)
      end
    else
      # debug_log "#{module_name} Sync finish."
      :ok
    end
  end

  defp human_readable_module(mod) do
    mod |> Module.split() |> List.last()
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
    Checks if we are currently syncing the DB.
  """
  def syncing?(%Context{database: db}), do: GenServer.call(db, :is_syncing?)

  @doc """
    Hooks into database events.
    will receive events in the form of:
    * `{Farmbot.Database, {syncable, `action`, id}}`

    Will also receive severl other special messages.
    * {Farmbot.Database, `:sync_start`}
    * {Farmbot.Database, `:sync_end`  }
    * {Farmbot.Database, `:sync_error`}

    ## Action
      * `add`    - an item was added
      * `update` - an item was modified
      * `remove` - an item was deleted
        * if `action` is remove, `id` may be "*" meaning all syncables were removed.
  """
  def hook(%Context{database:   db}, pid), do: GenServer.call(db, {:hook,   pid})

  @doc "Unsubscribes from database events."
  def unhook(%Context{database: db}, pid), do: GenServer.call(db, {:unhook, pid})

  @doc """
    Sets awaiting api resources.
  """
  @spec set_awaiting(Context.t, syncable, verb, any) :: :ok | no_return
  def set_awaiting(%Context{database: db} = ctx, syncable, verb, value) do
    debug_log("setting awaiting: #{syncable} #{verb}")
    # FIXME(connor) YAY SIDE EFFECTS
    set_syncing(ctx, :sync_now)
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
  def get_by_id(%Context{database: db}, kind, id),
    do: GenServer.call(db, {:get_by, kind, id})

  @doc """
    Get all resources of this kind.
  """
  @spec get_all(Context.t, syncable) :: [resource_map]
  def get_all(%Context{database: db}, kind),
    do: GenServer.call(db, {:get_all, kind})

  ## GenServer

  defmodule State do
    @moduledoc false
    alias Farmbot.Database.DB

    defimpl Inspect, for: __MODULE__ do
      def inspect(thing, _) do
        "#DatabaseState<#{inspect thing.all}>"
      end
    end

    defstruct [
      :by_kind_and_id,
      :awaiting,
      :by_kind,
      :context,
      :syncing,
      :hooks,
      :refs,
      :all
    ]

    @type t :: %{
      by_kind_and_id: %{ required({DB.syncable, DB.db_id}) => DB.ref_id       },
      awaiting:       %{ required(DB.syncable)             => boolean         },
      by_kind:        %{ required(DB.syncable)             => [DB.ref_id]     },
      context:        Context.t,
      syncing:        boolean,
      hooks:          [pid | atom],
      refs:           %{ required(DB.ref_id)               => DB.resource_map },
      all:            [DB.ref_id],
    }
  end

  @typedoc """
    State of the DB
  """
  @type state :: State.t

  @doc """
    Start the Database
  """
  def start_link(%Context{} = ctx, opts),
    do: GenServer.start_link(__MODULE__, ctx, opts)

  def init(context) do
    initial_by_kind_and_id = %{}
    initial_awaiting       = generate_keys(all_syncable_modules(), true)
    initial_by_kind        = generate_keys(all_syncable_modules())
    initial_hooks          = []
    initial_refs           = %{}
    initial_all            = []

    state = %State{
      by_kind_and_id: initial_by_kind_and_id,
      awaiting:       initial_awaiting,
      by_kind:        initial_by_kind,
      context:        context,
      syncing:        false,
      hooks:          initial_hooks,
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

  def handle_cast({:broadcast_sync, msg}, state) do
    for hook <- state.hooks do
      broadcast(hook, msg)
    end

    new_state = case msg do
      :sync_start -> %{state | syncing: true}
      :sync_end   -> %{state | syncing: false}
      _           -> state
    end
    {:noreply, new_state}
  end

  def handle_call(:is_syncing?, _, state), do: {:reply, state.syncing, state}

  def handle_call(:flush, _, old_state) do
    {:ok, new_state} = init([])
    {:reply, :ok, %{new_state | hooks: old_state}}
  end

  def handle_call({:hook, pid}, _, state) do
    {:reply, :ok, %{state | hooks: [pid | state.hooks]}}
  end

  def handle_call({:unhook, pid}, _, state) do
    new_hooks = List.delete(state.hooks, pid)
    {:reply, :ok, %{state | hooks: new_hooks}}
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

  def handle_call(
    {:set_awaiting, syncable, :remove, int_or_wildcard}, _, state)
  do
    new_state =
      case int_or_wildcard do
        "*" -> remove_all_syncable(state, syncable)
        num -> remove_syncable(state, syncable, num)
      end
    broadcast_to_hooks(state.hooks, syncable, :remove, int_or_wildcard)
    {
      :reply,
      :ok,
      %{ new_state | awaiting: %{ state.awaiting | syncable => true } }
    }
  end

  def handle_call({:set_awaiting, syncable, _verb, _}, _, state) do
    {:reply, :ok, %{ state | awaiting: %{ state.awaiting | syncable => true} }}
  end

  def handle_call({:unset_awaiting, syncable}, _, state) do
    {:reply, :ok, %{ state | awaiting: %{ state.awaiting | syncable => false} }}
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
      by_kind:        %{state.by_kind | syncable => []},
      refs:           new_refs,
      all:            new_all
     }
  end

  @spec remove_syncable(state, syncable, integer) :: state
  defp remove_syncable(state, syncable, num) do
    new_all = Enum.reject(state.all, fn({s, _, id}) ->
      (s == syncable) && (id == num)
    end)

    new_by_kind_and_id = state.by_kind_and_id
      |> Enum.reject(fn({{s, id}, _}) -> (s == syncable) && (id == num) end)
      |> Map.new

    new_refs = state.refs
      |> Enum.reject(fn({{s, _, id}, _}) ->
       (s == syncable) && (id == num)
      end)
      |> Map.new()

    %{
      state |
      by_kind_and_id: new_by_kind_and_id,
      all:            new_all,
      refs:           new_refs,
     }
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
    id   = Map.fetch!(record, :id)

    # Do we have it already?
    maybe_old = get_by_kind_and_id(state, kind, id)
    if maybe_old do
      debug_log("updating old record")
      already_exists = maybe_old
      # if it existed, update it.
      # set the ref from the old one.
      new = %{already_exists | body: record}
      new_refs = %{state.refs | new.ref_id => new}
      broadcast_to_hooks(state.hooks, kind, :update, id)
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

      broadcast_to_hooks(state.hooks, kind, :add, id)
      %{ state |
         refs:           new_refs,
         all:            all,
         by_kind:        by_kind,
         by_kind_and_id: by_kind_and_id }
    end
  end

  def terminate(_reason, state), do: set_syncing(state.context, :sync_now)

  defp broadcast_to_hooks([], _syncable, _action, _id), do: :ok
  defp broadcast_to_hooks([hook | rest], syncable, action, id) do
    broadcast(hook, {syncable, action, id})
    broadcast_to_hooks(rest, syncable, action, id)
  end

  defp broadcast(hook, msg) do
    send(hook, {__MODULE__, msg})
  end

end
