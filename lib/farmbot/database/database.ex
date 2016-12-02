defmodule Farmbot.Database do
  use Syncables
  @moduledoc """
    Farmbots database implementation.
  """
  use GenServer
  require Logger
  @log_tag "BotSync"

  @spec default_sync :: map
  defp default_sync do
    %{"compat_num" => -1,
      "device" => %{
        "id" => -1,
        "planting_area_id" => -1,
        "webcam_url" => "loading...",
        "name" => "loading..."
        },
      "peripherals" =>   [],
      "plants" =>        [],
      "regimen_items" => [],
      "regimens" =>      [],
      "sequences" =>     [],
      "users" =>         [],
      "tool_bays" =>     [],
      "tool_slots" =>    [],
      "tools" =>         []}
  end

  def init(_args) do
    token = case Farmbot.Auth.get_token() do
      {:ok, token} -> Token.create!(token)
      _ -> nil
    end
    initial_state =
      %{token: token,
        resources: load_old_resources}
    {:ok, initial_state}
  end

  def load_old_resources do
     default = SyncObject.create!(default_sync)
      case SafeStorage.read(__MODULE__.Resources) do
        {:ok, %SyncObject{} = old_state} -> old_state
        _ -> default
      end
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def handle_call({:stuff, %SyncObject{} = new}, {caller, _ref}, %{token: token, resources: old}) do
    # BUG THIS LOGIC NEEDS TO BE SOMEWHERE ELSE
    # IT CAUSES TIMEOUTS AND STUFF WHERE THERE SHOULD NOT BE ONE
    # old_perifs = old.peripherals
    # new_perifs = new.peripherals
    # if old_perifs != new_perifs do
    #   Enum.all?(new_perifs, fn(perif) ->
    #     Command.read_pin(perif.pin, perif.mode)
    #   end)
    # end
    new_merged = Map.merge(old ,new)
    SafeStorage.write(__MODULE__.Resources, :erlang.term_to_binary(new_merged))
    send caller, {:sync_complete, new_merged}
    {:reply, new, %{token: token, resources: new_merged}}
  end

  def handle_call(:fetch_all, _from, %{token: token, resources: %SyncObject{} = resources}) do
    {:reply, resources, %{token: token, resources: resources}}
  end

  # build the headers to get stuff from the API.
  def handle_call(:api_creds, _from, %{token: %Token{} = token, resources: %SyncObject{} = resources}) do
    headers =
      ["Content-Type": "application/json",
       "Authorization": "Bearer " <> token.encoded]
    {:reply, {:headers, headers}, %{token: token, resources: resources}}
  end

  # If we don't have a token yet.
  def handle_call(:api_creds, _from, %{token: token, resources: %SyncObject{} = resources}) do
    {:reply, {:error, :no_token}, %{token: token, resources: resources}}
  end

  def handle_call(_,_,%{token: token, resources: resources}) do
    {:reply, :bad_resources, %{token: token, resources: default_sync}}
  end

  def handle_info({:authorization, token}, %{token: _, resources: resources}) do
    {:noreply, %{token: Token.create!(token), resources: resources}}
  end

  # Public api

  @spec sync :: Sync.t | {:error, atom}
  @doc """
    Pulls down the latest syncables from the api.
  """
  def sync do
    case do_sync do
      %SyncObject{} = thing ->
        Farmbot.Logger.log("Synced", [], [@log_tag])
        thing
      {:error, reason} ->
        Logger.error("Farmbot Sync: #{inspect reason}")
        Farmbot.Logger.log("Error Syncing! #{inspect reason}", [:error_toast], [@log_tag])
        {:error, reason}
    end
  end

  @spec do_sync :: Sync.t | {:error, atom}
  defp do_sync do
    with {:headers, headers} <- GenServer.call(__MODULE__, :api_creds),
    do: Farmbot.BotState.get_server |> do_sync(headers)
  end

  # TODO: Fix this any
  @spec do_sync(nil | String.t, [any,...]) :: Sync.t | {:error, atom}
  defp do_sync(nil, _headers), do: {:error, :no_server}
  defp do_sync(server, headers) do
    HTTPotion.get("#{server}/api/sync", [headers: headers]) |> handle_http
  end

  @spec handle_http(HTTPotion.Response.t | HTTPotion.ErrorResponse.t)
  :: Sync.t | {:error, atom}
  defp handle_http(%HTTPotion.ErrorResponse{message: message}), do: {:error, message}
  defp handle_http(%HTTPotion.Response{body: body, headers: _headers, status_code: 200}) do
    with {:ok, json} <- Poison.decode(body),
    do: SyncObject.create(json) |> put_stuff
  end

  @spec put_stuff(SyncObject.t | any) :: Sync.t | {:error, :bad_sync}
  def put_stuff({:ok, %SyncObject{} = stuff}), do: GenServer.call(__MODULE__, {:stuff, stuff})
  def put_stuff(error), do: {:error, error}
end
