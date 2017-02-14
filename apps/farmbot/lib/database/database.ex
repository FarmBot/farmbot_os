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
  alias Farmbot.ImageWatcher
  require Logger
  alias Farmbot.Sync.SyncObject
  alias Farmbot.Sync.Database.Diff
  alias Farmbot.BotState.ProcessTracker, as: PT
  @save_file "/tmp/sync_object.save"

  defdatabase Database do
    use Amnesia
    @moduledoc """
      The Database that holds all the objects found on the Farmbot Web Api
    """

    # Syncables
    syncable Device, [:id, :planting_area_id, :name, :webcam_url]
    syncable Peripheral,
      [:id, :device_id, :pin, :mode, :label, :created_at, :updated_at]
    syncable Plant, [:id, :device_id, :name, :x, :y, :radius]
    syncable Point, [:id, :radius, :x, :y, :z, :meta]
    syncable Regimen, [:id, :color, :name, :device_id]
    syncable RegimenItem, [:id, :time_offset, :regimen_id, :sequence_id]
    syncable Sequence, [:id, :args, :body, :color, :device_id, :kind, :name]
    syncable ToolBay, [:id, :device_id, :name]
    syncable ToolSlot, [:id, :tool_bay_id, :tool_id, :name, :x, :y, :z]
    syncable Tool, [:id, :name]
    syncable User, [:id, :device_id, :name, :email, :created_at, :updated_at]
    syncable FarmEvent,
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
    Downloads the sync object form the API.
  """
  def sync do
    with {:ok, so} <- down(),
         :ok <- up()
    do
      save_recent_so(so)
      {:ok, so}
    end
  end

  # TODO(Connor) put this in Redis.
  @spec save_recent_so(SyncObject.t) :: no_return
  defp save_recent_so(%SyncObject{} = so) do
    f = so |> :erlang.term_to_binary
    File.write(@save_file, f)
  end

  @doc """
    Loads the most recent sync without actually syncing.
  """
  @spec load_recent_so :: {:ok, SyncObject.t} | no_return
  def load_recent_so do
    f =
      @save_file
      |> File.read!
      |> :erlang.binary_to_term
    {:ok, f}
  end

  # downloads all the information from the api
  @spec down :: {:ok, SyncObject.t} | {:error, term}
  defp down do
    with {:ok, resp} <- fetch_sync_object(),
         {:ok, json} <- parse_http(resp),
         {:ok, parsed} <- Poison.decode(json),
         {:ok, validated} <- SyncObject.validate(parsed),
         do: enter_into_db(validated)
  end

  # uploads all the information to the api
  @spec up :: :ok | {:error, term}
  defp up do
    with :ok <- ImageWatcher.force_upload, do: :ok
  end

  defp enter_into_db(%SyncObject{} = so) do
    # HACK(Connor) please just ignore this
    # This is some diffing on the old Farm Events.
    spawn fn() ->
      fes = Map.get(so, :farm_events)
      list = fes |> Diff.diff |> MapSet.to_list
      for farm_event <- list do
        maybe_info = PT.lookup(:event, farm_event.id)
        if maybe_info, do: PT.deregister(maybe_info.uuid)
        PT.register(:event, farm_event.id, farm_event)
      end
    end

    clear_all(so)
    Amnesia.transaction do
      # We arent aloud to enumerate over a struct, so we turn it into a map here
      blah = Map.from_struct(so)
      # Then enumerate over it.
      struct =
        blah
        |> Enum.map(fn({key, val}) ->
          {key, parse_and_write(val)}
        end)
        # then turn it back into a map
        |> Map.new
        # then turn it back into a struct
        |> to_struct(SyncObject)
      {:ok, struct}
    end
  end

  defp enter_into_db(_), do: {:error, :bad_sync_object}

  # This needs to happen before we start a transaction
  defp clear_all(%SyncObject{} = so) do
    keys = Map.keys(so) -- [:__struct__]
    for key <- keys, do: atom_to_module(key).clear()
  end

  @spec atom_to_module(atom) :: term
  defp atom_to_module(:device), do: Farmbot.Sync.Database.Device
  defp atom_to_module(key) do
    blah = key |> Atom.to_string |> Macro.camelize |> String.trim_trailing("s")
    Module.concat([Farmbot.Sync.Database, blah])
  end

  # make struct function pipable.
  defp to_struct(map, module), do: struct(module, map)

  @doc """
    Takes a single database object and turns it into a list of things
    and pushes it back thru again.
  """
  def parse_and_write(thing) when is_map(thing), do: parse_and_write([thing])

  @doc """
    Takes a list of Database Objects
      * figures out what kind of object the thing is.
      * checks if there is already an object under this id
        * if there is, hunts it down and destroys it
      * Writes the new one.
  """
  def parse_and_write(list_of_things) when is_list(list_of_things) do
    Enum.map(list_of_things, fn(thing) ->
      # im so cute.
      module = thing.__struct__

      # OK. GET READY TO LEARN SOMETHING
      # SINCE WE DONT WANT TO KEEP TRACK OF :id OURSELVES,
      # WE HAVE TO MAKE OUR TABLES A :bag
      # THIS MEANS THAT EVERY TIME WE ENTER SOMETHING INTO THE
      # DATABASE WE HAVE TO CHECK FOR ITS EXISTANCE
      # THESE FOUR LINES OF PURE GOLD IS THAT
      case module.read(thing.id) do
        # IF IT WAS nil WE ARE FINE.
        nil -> nil
        # BUT IF ITS A ONE ITEM LIST OF A STRUCT OF THIS MODULE,
        # WE NEED TO DELETE
        # IT FROM THE DB BEFORE WRITING THE NEW ONE IN.
        [%module{} = delete_me] -> module.delete(delete_me)
        # WHICH IS ALL FINE AS LONG AS THIS DOES NOT HAPPEN
        # IF IT DOES THERE MAY OR MAY NOT BE AN N+1 ISSUE.
        # other_list -> Enum.each(other_list, fn(t) -> module.delete(t) end)
      end
      # This is where we actually write the new thing.
      module.write(thing)
    end)
  end

  @doc """
    Tries to do an HTTP request on server/api/sync
  """
  # NOTE(Connor) we might need to chunk this out. Getting the entire sync
  # object everytime is pretty time consuming
  @spec fetch_sync_object :: {:error, atom} | {:ok, HTTPoison.Response.t}
  def fetch_sync_object do
     case Farmbot.HTTP.get("/api/sync", [], [recv_timeout: 20_000]) do
       {:ok, %HTTPoison.Response{} = f} -> {:ok, f}
       {:error, %HTTPoison.Error{reason: reason}} -> {:error, reason}
       error -> {:error, error}
     end
  end

  @spec parse_http(any) :: {:ok, map} | {:error, atom}
  defp parse_http({:error, reason}), do: {:error, reason}
  defp parse_http(%HTTPoison.Response{body: b, status_code: 200}), do: {:ok, b}
  defp parse_http(error), do: {:error, error}
end
