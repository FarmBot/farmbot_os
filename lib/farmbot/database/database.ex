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
  import Syncable
  alias Farmbot.Sync.Helpers

  defdatabase Database do
    use Amnesia
    @moduledoc """
      The Database that holds all the objects found on the Farmbot Web Api
    """

    # Syncables
    syncable Device, [:id, :planting_area_id, :name, :webcam_url]
    syncable Peripheral,
      [:id, :device_id, :pin, :mode, :label, :created_at, :updated_at]
    syncable Regimen, [:id, :color, :name, :device_id]
    syncable RegimenItem, [ :id, :time_offset, :regimen_id, :sequence_id]
    syncable Sequence, [:args, :body, :color, :device_id, :id, :kind, :name]
    syncable ToolBay, [:id, :device_id, :name]
    syncable ToolSlot, [:id, :tool_bay_id, :name, :x, :y, :z]
    syncable Tool, [:id, :slot_id, :name]
    syncable User, [ :id, :device_id, :name, :email, :created_at, :updated_at]
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

  @doc """
    Downloads the sync object form the API.
  """
  def sync do
    # TODO MAKE THIS MORE GENERIC SO I CAN USE IT FOR GENERIC API REQUESTS
    with {:ok, json_token}  <- fetch_token,
         {:ok, token}       <- Token.create(json_token),
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
        Enum.map(blah, fn({key, val}) ->
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

  def parse_and_write(thing) when is_map(thing), do: parse_and_write([thing])

  def parse_and_write(list_of_things) when is_list(list_of_things) do
    Enum.map(list_of_things, fn(thing) ->
      module = thing.__struct__
      module.write(thing)
    end)
  end

  @doc """
    Gets a token from Farmbot.Auth
  """
  def fetch_token do
    case Farmbot.Auth.get_token do
      nil -> {:error, :no_token}
      {:error, reason} -> {:error, reason}
      json_token -> {:ok, json_token}
    end
  end

  def fetch_server do
    case Farmbot.BotState.get_server do
      nil -> {:error, :no_server}
      {:error, reason} -> {:error, reason}
      server -> {:ok, server}
    end
  end

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
