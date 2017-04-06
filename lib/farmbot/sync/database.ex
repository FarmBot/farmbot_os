defmodule Farmbot.Sync do
  @moduledoc """
    There is a quite a bit of macros going on here.
      * defdatabase comes from Amnesia
      * defindes a database. This should only show up once.
      * syncable comes from Syncable and defines a database table.
  """

  use Amnesia
  import Syncable
  alias Farmbot.Sync.Helpers
  alias Farmbot.ImageWatcher
  require Logger

  defdatabase Database do
    use Amnesia
    @moduledoc """
      The Database that holds all the objects found on the Farmbot Web Api
    """

    # Syncables
    syncable Device, "/api/device",
      [:id, :planting_area_id, :name, :webcam_url], singular: true

    syncable Peripheral, "/api/peripherals",
      [:id, :pin, :mode, :label, :created_at, :updated_at]

    syncable Plant, "/api/plants",
      [:id, :name, :x, :y, :radius]

    syncable Point, "/api/points",
      [:id, :radius, :x, :y, :z, :meta]

    syncable Regimen, "/api/regimens",
      [:id, :color, :name, :regimen_items]

    # syncable RegimenItem, "/api/regimen_items",
    #   [:id, :time_offset, :regimen_id, :sequence_id]

    syncable Sequence, "/api/sequences",
      [:id, :args, :body, :color, :kind, :name]

    syncable ToolBay, "/api/tool_bays",
      [:id, :name]

    syncable ToolSlot, "/api/tool_slots",
      [:id, :tool_bay_id, :tool_id, :name, :x, :y, :z]

    syncable Tool, "/api/tools",
      [:id, :name]

    syncable User, "/api/users",
      [:id, :name, :email, :created_at, :updated_at]

    syncable FarmEvent, "/api/farm_events",
      [:id, :start_time, :end_time, :next_time,
       :repeat, :time_unit, :executable_id, :executable_type, :calendar]
  end

  # These have to exist because Amnesia.where gets confused when you
  # Screw with context.
  @doc "Gets a device by id"
  def get_device(id), do: Helpers.get_device(id)

  @doc "Gets a farm event by id"
  def get_farm_event(id), do: Helpers.get_farm_event(id)

  @doc "Gets a peripheral by id"
  def get_peripheral(id), do: Helpers.get_peripheral(id)

  @doc "Gets a point by id"
  def get_point(id), do: Helpers.get_point(id)

  # @doc "Gets a regimen item by id"
  # def get_regimen_item(id), do: Helpers.get_regimen_item(id)

  @doc "Gets a regimen by id"
  def get_regimen(id), do: Helpers.get_regimen(id)

  @doc "Gets a sequence by id"
  def get_sequence(id), do: Helpers.get_sequence(id)

  @doc "Gets a tool bay by id"
  def get_tool_bay(id), do: Helpers.get_tool_bay(id)

  @doc "Gets a tool slot by id"
  def get_tool_slot(id), do: Helpers.get_tool_slot(id)

  @doc "Gets a tool by id"
  def get_tool(id), do: Helpers.get_tool(id)

  @doc "Gets a user by id"
  def get_user(id), do: Helpers.get_user(id)

  @doc "Get The current device name"
  def device_name, do: Helpers.get_device_name

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

    out_of_sync = Farmbot.Sync.Cache.get_state
    if Enum.empty?(out_of_sync) do
      sync_all()
    else
      sync_some(out_of_sync)
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
  defp to_module_syncable(:tool_bays), do: Database.ToolBay
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
    Database.ToolBay,
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
