defmodule Farmbot.Sync do
  @moduledoc """

  """

  import Syncable
  alias Farmbot.ImageWatcher
  require Logger

  @doc """
    Downloads all the relevant information from the api
  """
  @spec sync ::
    {:ok, %{required(atom) => [map] | map}} | {:error, term}
  # This is the most complex method in all of this application.
  def sync do
    Farmbot.BotState.set_sync_msg :syncing

    # TODO(Connor) Should probably move this to its own function
    # but right now its only one thing
    Logger.info ">> is checking for images to be uploaded."
    :ok = ImageWatcher.force_upload

    case check_last_sync() do
      :no_last_sync ->
        Logger.info ">> Could not find sync cache. Creating new."
        sync_all()
      _date_str ->
        out_of_sync = Farmbot.Sync.Cache.get_out_of_sync
        if Enum.empty?(out_of_sync) do
          Logger.info ">> Cache empty. Doing full sync."
          sync_all()
        else
          Logger.debug ">> Only syncing changed items."
          sync_some(out_of_sync)
        end
    end
  end

  @spec last_sync_path :: binary
  defp last_sync_path, do: "/tmp/last_sync"

  # Checks if this is the first sync or not.
  @spec check_last_sync() :: :no_last_sync | binary
  defp check_last_sync do
    case File.read(last_sync_path()) do
      {:ok, date} -> String.trim date
      _ -> :no_last_sync
    end
  end

  @spec set_last_sync :: :ok | {:error, :file.posix}
  defp set_last_sync do
    now_str = Timex.now() |> to_string
    Farmbot.System.FS.transaction fn() ->
      File.write(last_sync_path(), now_str)
    end
  end

  @type stuff :: Farmbot.Sync.Cache.state
  @spec sync_some(stuff)
    :: {:ok, %{required(atom) => [map] | map}} | {:error, term}
  defp sync_some(some) do
    # TODO(Connor) this is incomplete
    blerp = Enum.map(some, fn({syncable, _cached_thing}) ->
      to_module_syncable(syncable)
    end)
    Farmbot.Sync.Cache.clear()
    sync_all(blerp)
  end

  # ignore this pls
  @spec to_module_syncable(atom) :: atom
  defp to_module_syncable(:devices), do: Database.Device
  defp to_module_syncable(:device), do: Database.Device
  defp to_module_syncable(:peripherals), do: Database.Peripheral
  defp to_module_syncable(:plants), do: Database.Plant
  defp to_module_syncable(:points), do: Database.Point
  defp to_module_syncable(:regimens), do: Database.Regimen
  defp to_module_syncable(:sequences), do: Database.Sequence
  defp to_module_syncable(:tool_slots), do: Database.ToolSlot
  defp to_module_syncable(:tools), do: Database.Tool
  defp to_module_syncable(:users), do: Database.User
  defp to_module_syncable(:farm_events), do: Database.FarmEvent

  @spec sync_all(atom)
    :: {:ok, %{required(atom) => [map] | map}} | {:error, term}
  defp sync_all(list_of_syncables \\ nil) do
    # im so lazy.
    syncables = list_of_syncables || all_syncables()

    # Clear the db (Enumeration 1)
    clear_all(syncables)

    # Build a list of tasks (Enumeration 2)
    {tasks, refs} = create_tasks(syncables)

    # Wait for the tasks to finish (I guess doesnt count)
    tasks_with_results = Task.yield_many(tasks, 20_000)

    # enumerate the results (Enumeration 3)
    {success, fails} = task_results(tasks_with_results, refs)

    # print logs etc (Enumeration 4)
    return(success, fails)
  end

  @spec clear_all(syncables) :: [:ok] | no_return
  defp clear_all(syncables) do
    Logger.info ">> is clearing old data."
    # this is ugly sorry.
    for mod <- syncables do
      mod.clear()
    end
  end

  @spec create_tasks(syncables) :: {[Task.t], %{required(Task.t) => atom}}
  defp create_tasks(syncables) do
    Logger.info ">> is downloading data!", type: :busy
    Enum.reduce(syncables, {[], %{}}, fn(mod, {tasks, refs}) ->
      task = Task.async(fn ->
        mod.fetch
      end)
      {[task | tasks], Map.put(refs, task, mod)}
    end)
  end

  @spec task_results([Task.t], %{required(Task.t) => atom}) ::
    {%{required(atom) => [map] | map}, [{atom, term}]}
  defp task_results(tasks_with_results, refs) do
    Enum.reduce(tasks_with_results, {%{}, []},
      fn({task, res}, {success, fail}) ->
        mod = refs[task]
        handle_results(mod, task, res, {success, fail})
      end)
  end

  @spec handle_results(atom, Task.t, any,
    {%{required(atom) => [map] | map}, [{atom, term}]})
    :: { %{required(atom) => [map] | map}, [{atom, term}]}
  defp handle_results(mod, _task, {:ok, results}, {success, fail}) do
    case results do
      {:ok, object} -> {Map.put(success, mod, object), fail}
      {:error, _reason} = er -> {success, [{mod, er} | fail]}
    end
  end

  defp handle_results(mod, task, _results, {success, fail}) do
    Task.shutdown(task, :brutal_kill)
    {success, [{mod, :timeout} | fail]}
  end

  @spec return(%{required(atom) => [map] | map}, [{:error, term}]) ::
    {:ok, %{required(atom) => [map] | map}} | {:error, [{atom, term}]}
  defp return(success, fails) do
    # if there are no errors, return success, if not, return the fails
    if Enum.empty?(fails) do
      Logger.info ">> is synced!", type: :success
      Farmbot.BotState.set_sync_msg :synced
      # This might be concidered a side effect.
      set_last_sync()
      {:ok, success}
    else
      Logger.error ">> encountered errors syncing: #{inspect fails}"
      Farmbot.BotState.set_sync_msg :sync_error
      {:error, fails}
    end
  end

  @typedoc """
    List of all syncables.
  """
  @type syncables :: [atom]

  @doc """
    All syncables
  """
  @spec all_syncables :: syncables
  def all_syncables, do: [
    Database.Device,
    Database.Peripheral,
    Database.Plant,
    Database.Point,
    Database.Regimen,
    # Database.RegimenItem,
    Database.Sequence,
    Database.ToolSlot,
    Database.Tool,
    # Database.User,
    Database.FarmEvent,
  ]

  defmacro __using__(_) do
    s = all_syncables()
    quote do
      use Amnesia
      for mod <- unquote(s) do
        alias mod
        use mod
      end
    end
  end
end
