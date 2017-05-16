defmodule Farmbot.Database do
  @moduledoc """
    Database Implementation.
  """

  use GenServer
  require Logger

  @typedoc """
    The module name of the object you want to access.
  """
  @type syncable :: :device | :farm_event | atom

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
  @type resource_identifier :: {syncable, local_id, db_id}

  @typedoc """
    Held in `refs`.
  """
  @type resource_map :: %{kind: syncable, uuid: uuid, body: body}

  @typedoc """
    The contents of a `syncable`.
  """
  @type body :: map

  @typedoc false
  @type uuid :: binary

  @typedoc false
  @type verb :: Farmbot.CeleryScript.Command.DataUpdate.verb

  @typedoc """
    State of the DB
  """
  @type state :: %{
    all: [resource_identifier],

    by_kind: %{
      required(syncable) => [resource_identifier]
    },

    by_kind_and_id: %{
      required({syncable, db_id}) => resource_identifier
    },
    by_uuid: %{
      required(uuid) => resource_identifier
    },
    refs: %{
      required(resource_identifier) => resource_map
    },
    outdated: %{
      add:    [resource_identifier],
      remove: [resource_identifier],
      update: [resource_identifier]
    }
  }
  syncable_modules =
    "lib/farmbot/database/syncable/"
    |> File.ls!
    |> Enum.map(fn(file_name) ->
         mod_name_str = String.trim(file_name, ".ex")
         mod_name     = Macro.camelize(mod_name_str)
         Module.concat([Farmbot.Database.Syncable, mod_name])
    end)
  @doc """
    Sync up with the API.
  """
  def sync do
    outdated = GenServer.call(__MODULE__, :get_outdated)
    # TODO: Probably better ways to do this.
    if Enum.empty?(outdated) do
      # Full sync - need all the things
      for module_name <- all_the_syncables() do
        module_name.fetch({__MODULE__, :commit_records, [module_name]})
      end
    else
      outdated
        |> Map.to_list
        |> map_out_date
    end
  end

  def commit_records([record | rest], mod_name) do
    commit_records(record)
    commit_records(rest)
  end

  def commit_records([], mod_name) do
    :ok
  end

  def commit_records(record, mod_name) when is_map(record) do
    GenServer.call({:update_or_create, record})
  end

  def commit_records({:error, reason}, mod_name) do
    Logger.error("#{mod_name}: #{reason}")
  end

  def all_the_syncables() do
   unquote(syncable_modules)
  end

  defp map_out_date([]) do
    :ok
  end

  defp map_out_date([{verb, items} | rest]) do
    flush_outdated(verb, items)
    map_out_date(rest)
  end

  defp flush_outdated(:add, resource_id_list) do
    # push into the index
  end

  defp flush_outdated(:remove, resource_id_list) do
    # splice out of the index
  end

  defp flush_outdated(:update, resource_id_list) do
  end

  def handle_call(:get_outdated, _, state) do
    {:reply, state.outdated, state}
  end

  @doc """
    Sets outdated api resources.
  """
  def set_outdated(syncable, verb, value) do
    GenServer.cast(__MODULE__, {:set_outdated, syncable, verb, value})
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

  @doc """
    Get a resource by its (local) uuid.
  """
  @spec get_by_uuid(uuid) :: resource_map | nil
  def get_by_uuid(uuid), do: GenServer.call(__MODULE__, {:get_by, uuid})

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
      by_kind: %{},
      by_kind_and_id: %{},
      by_uuid: %{},
      outdated: %{},
      refs: %{}
    }
    {:ok, state}
  end

  def handle_call({:get_by, kind, id}, _, state) do
    r = get_by_kind_and_id(state, kind, id)
    {:reply, r, state}
  end

  def handle_call({:get_by, uuid}, _, state) do
    r = case state.by_uuid[uuid] do
      {_syncable, _local_id, _db_id} = ref ->
        state.refs[ref]
      _ -> nil
    end
    {:reply, r, state}
  end

  def handle_call({:get_all, syncable}, _, state) do
    {:reply, get_all(state, syncable), state}
  end

  def handle_call({:update_or_create, record}, _, state) do
    # Do we have it already?
  end
  # wildcard is easy
  def handle_cast({:set_outdated, syncable, verb, "*"}, state) do
    # get a list of all references of this type.
    all = state.by_kind[syncable]

    # update the updated field
    new_outdated = %{state.outdated | verb => all}

    # update the state.
    new_state = %{state | outdated: new_outdated}
    {:noreply, new_state}
  end

  def handle_cast({:set_outdated, syncable, verb, id}, state) do
    # get the reference by its kind and id.
    ref = get_by_kind_and_id(state, syncable, id)

    # old list of things that were out dated
    old_by_verb = state.outdated[verb]

    # new list ^
    new_by_verb = [ref | old_by_verb]

    # update the verb with new info from above.
    new_outdated = %{state.outdated | verb => new_by_verb}

    new_state = %{state | outdated: new_outdated}
    {:noreply, new_state}
  end

  # returns all the references of syncable
  defp get_all(state, syncable) do
    all = state.by_kind[syncable]
    if all do
      Enum.map(all, fn(ref) -> state.refs[ref] end)
    else
      []
    end
  end

  defp get_by_kind_and_id(state, kind, id) do
    case state.by_kind[kind] do
      {_kind, _local_id, db_id} = ref when id == db_id ->
        state.refs[ref]
      _ -> nil
    end
  end
end
