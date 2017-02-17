defmodule Farmbot.Sync do
  @moduledoc """
    There is a quite a bit of macros going on here.
      * `defdatabase` comes from `Amnesia`
        * defindes a database. This should only show up once.
      * syncable comes from `Syncable` and defines a database table.
  """

  use Amnesia
  import Syncable
  alias Farmbot.Sync.Helpers
  # alias Farmbot.ImageWatcher
  # alias Farmbot.Sync.Database.Diff
  require Logger
  # alias Farmbot.BotState.ProcessTracker, as: PT

  defdatabase Database do
    use Amnesia
    @moduledoc """
      The Database that holds all the objects found on the Farmbot Web Api
    """

    # Syncables
    syncable Device, "/api/device",
      [:id, :planting_area_id, :name, :webcam_url], singular: true

    syncable Peripheral, "/api/peripherals",
      [:id, :device_id, :pin, :mode, :label, :created_at, :updated_at]

    syncable Plant, "/api/plants",
      [:id, :device_id, :name, :x, :y, :radius]

    syncable Point, "/api/points",
      [:id, :radius, :x, :y, :z, :meta]

    syncable Regimen, "/api/regimens",
      [:id, :color, :name, :device_id]

    syncable RegimenItem, "/api/regimen_items",
      [:id, :time_offset, :regimen_id, :sequence_id]

    syncable Sequence, "/api/sequences",
      [:id, :args, :body, :color, :device_id, :kind, :name]

    syncable ToolBay, "/api/tool_bays",
      [:id, :device_id, :name]

    syncable ToolSlot, "/api/tool_slots",
      [:id, :tool_bay_id, :tool_id, :name, :x, :y, :z]

    syncable Tool, "/api/tools",
      [:id, :name]

    syncable User, "/api/users",
      [:id, :device_id, :name, :email, :created_at, :updated_at]

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

  @doc "Gets a regimen item by id"
  def get_regimen_item(id), do: Helpers.get_regimen_item(id)

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
  @spec sync :: :ok | {:error, term}
  def sync do
    # :ok = ImageWatcher.force_upload
    # Build a list of tasks
    {tasks, refs} =
      Enum.reduce(all_syncables(), {[], %{}}, fn(mod, {tasks, refs}) ->
        task = Task.async(fn -> mod.fetch end)
        {[task | tasks], Map.put(refs, task, mod)}
      end)

    # Wait for the tasks to finish
    tasks_with_results = Task.yield_many(tasks, 5_000)

    # enumerate the results
    {success, fails} =
      Enum.reduce(tasks_with_results, {%{}, []}, fn({task, res}, {success, fail}) ->
        mod = refs[task]
        case res do
          # if the task completed.
          {:ok, result} ->
            # IO.inspect res
            # {:ok, {:ok, [%Farmbot.Sync.Database.Tool{id: 1, name: "Trench Digging Tool"}]}}
            # {:ok, {:ok, []}}
            # IO.puts "\n"
            case result do
              {:ok, object} -> {Map.put(success, mod, object), fail}
              {:error, _reason} = er -> {success, [{mod, er} | fail]}
            end

          # if after 10 seconds there was no result for this task, call it
          # an error, and kill the task.
          nil ->
            Task.shutdown(task, :brutal_kill)
            {success, [{mod, :timeout} | fail]}
        end
      end)
    # if there are no errors, return success, if not, return the fails
    if Enum.empty?(fails), do: success, else: {:error, fails}
  end

  defp all_syncables, do: [
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
end
