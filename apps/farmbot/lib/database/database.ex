alias Farmbot.Sync.SyncObject
defmodule Farmbot.Sync do
  @moduledoc """
    There is a quite a bit of macros going on here.
      * `defdatabase` comes from `Amnesia`
        * defindes a database. This should only show up once.
      * `generate` comes from `Farmbot.Sync.Macros`
        * Should happen once for every syncable object from the api.
        * Needs to be given all the wanted keys that will exist from the api
      * `mutation` comes from `Syncable`
        * takes a key that exists in `generate module`
        * given the variable `before` one can create a new value with that.
        * must return {:ok, new_thing}
  """
  use Amnesia
  alias Farmbot.Syncable
  import Farmbot.Syncable
  alias Farmbot.Sync.Helpers
  alias Farmbot.Auth
  alias Farmbot.BotState
  alias Farmbot.Token

  defdatabase Database do
    use Amnesia
    @moduledoc """
      The Database that holds all the objects found on the Farmbot Web Api
    """

    # Syncables
    syncable Device, [:id, :planting_area_id, :name, :webcam_url]
    syncable Peripheral,
      [:id, :device_id, :pin, :mode, :label, :created_at, :updated_at]
    syncable Plant, [:id, :device_id]
    syncable Regimen, [:id, :color, :name, :device_id]
    syncable RegimenItem, [:id, :time_offset, :regimen_id, :sequence_id]
    syncable Sequence, [:id, :args, :body, :color, :device_id, :kind, :name]
    syncable ToolBay, [:id, :device_id, :name]
    syncable ToolSlot, [:id, :tool_bay_id, :tool_id, :name, :x, :y, :z]
    syncable Tool, [:id, :name]
    syncable User, [:id, :device_id, :name, :email, :created_at, :updated_at]
  end

  # These have to exist because Amnesia.where gets confused when you
  # Screw with context.
  def get_device(id), do: Helpers.get_device(id)
  def get_peripheral(id), do: Helpers.get_peripheral(id)
  def get_regimen_item(id), do: Helpers.get_regimen_item(id)
  def get_regimen(id), do: Helpers.get_regimen(id)
  def get_sequence(id), do: Helpers.get_sequence(id)
  def get_tool_bay(id), do: Helpers.get_tool_bay(id)
  def get_tool_slot(id), do: Helpers.get_tool_slot(id)
  def get_tool(id), do: Helpers.get_tool(id)
  def get_user(id), do: Helpers.get_user(id)

  def device_name, do: Helpers.get_device_name

  @doc """
    Downloads the sync object form the API.
  """
  def sync do
    with {:ok, token}       <- fetch_token,
         {:ok, server}      <- fetch_server,
         {:ok, resp}        <- fetch_sync_object(server, token),
         {:ok, json}        <- parse_http(resp),
         {:ok, parsed}      <- Poison.decode(json),
         {:ok, validated}   <- SyncObject.validate(parsed),
         {:ok, ^validated}  <- enter_into_db(validated),
         do: {:ok, validated}
  end

  def enter_into_db(%SyncObject{} = so) do
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

  def enter_into_db(_), do: {:error, :bad_sync_object}

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
    Gets a token from Auth
  """
  def fetch_token, do: Auth.get_token

  @doc """
    Gets the server from Auth.
  """
  def fetch_server, do: Auth.get_server

  @doc """
    Tries to do an HTTP request on server/api/sync
  """
  @spec fetch_sync_object(nil | String.t, Token.t | any)
  :: {:error, atom} | {:ok, HTTPotion.Response.t | HTTPotion.ErrorResponse.t}
  def fetch_sync_object(nil, _), do: {:error, :bad_server}
  def fetch_sync_object(server, %Token{} = token) do
    headers =
      ["Content-Type": "application/json",
       "Authorization": "Bearer " <> token.encoded]
    {:ok, HTTPotion.get("#{server}/api/sync", [headers: headers])}
  end
  def fetch_sync_object(_server, _token), do: {:error, :bad_token}

  @doc """
    Parses HTTPotion responses
  """
  @spec parse_http(HTTPotion.Response.t | HTTPotion.ErrorResponse.t)
  :: {:ok, map} | {:error, atom}
  def parse_http(%HTTPotion.ErrorResponse{message: m}), do: {:error, m}
  def parse_http(%HTTPotion.Response{body: b, headers: _headers, status_code: 200}) do
    {:ok, b}
  end
  def parse_http(error), do: {:error, error}
end
