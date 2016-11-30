defmodule Farmbot.Sync do
  @moduledoc """
    This basically a database implementation. It is very possible that
    it gets replaced with sql or something.

    The state of this module should persist across reboots.
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
      "tool_bays" =>     []}
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
     default = Sync.create!(default_sync)
      case SafeStorage.read(__MODULE__.Resources) do
        {:ok, %Sync{} = old_state} -> old_state
        _ -> default
      end
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def handle_call({:stuff, %Sync{} = new}, {caller, _ref}, %{token: token, resources: old}) do
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

  def handle_call(:fetch_all, _from, %{token: token, resources: %Sync{} = resources}) do
    {:reply, resources, %{token: token, resources: resources}}
  end

  def handle_call({:get_sequence, id}, _from, %{token: token, resources: %Sync{} = resources}) do
    sequences = resources.sequences
    got = Enum.find(sequences, fn(sequence) -> Map.get(sequence, :id) == id end)
    {:reply, got, %{token: token, resources: resources}}
  end

  def handle_call(:get_sequences, _from, %{token: token, resources: %Sync{} = resources}) do
    {:reply, resources.sequences, %{token: token, resources: resources}}
  end

  def handle_call({:get_regimen, id}, _from, %{token: token, resources: %Sync{} = resources}) do
    regimens = resources.regimens
    got = Enum.find(regimens, fn(regimen) -> Map.get(regimen, :id) == id end)
    {:reply, got, %{token: token, resources: resources}}
  end

  def handle_call(:get_regimens, _from, %{token: token, resources: %Sync{} = resources}) do
    {:reply, resources.regimens, %{token: token, resources: resources}}
  end

  def handle_call({:get_regimen_item, id}, _from, %{token: token, resources: %Sync{} = resources}) do
    regimen_items = resources.regimen_items
    got = Enum.find(regimen_items, fn(regimen_item) -> regimen_item.id == id end)
    {:reply, got, %{token: token, resources: resources}}
  end

  def handle_call(:get_regimen_items, _from, %{token: token, resources: %Sync{} = resources}) do
    regimen_items = resources.regimen_items
    {:reply, regimen_items, %{token: token, resources: resources}}
  end

  def handle_call(:get_users, _from, %{token: token, resources: %Sync{} = resources}) do
    {:reply, resources.users, %{token: token, resources: resources}}
  end

  # build the headers to get stuff from the API.
  def handle_call(:api_creds, _from, %{token: %Token{} = token, resources: %Sync{} = resources}) do
    headers =
      ["Content-Type": "application/json",
       "Authorization": "Bearer " <> token.encoded]
    {:reply, {:headers, headers}, %{token: token, resources: resources}}
  end

  # If we don't have a token yet.
  def handle_call(:api_creds, _from, %{token: token, resources: %Sync{} = resources}) do
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
      %Sync{} = thing ->
        Farmbot.Logger.log("Synced", [], [@log_tag])
        thing
      {:error, reason} ->
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
    HTTPotion.get("#{server}/api/sync", [headers: headers]) |> handle_sync
  end

  @spec handle_sync(HTTPotion.Response.t | HTTPotion.ErrorResponse.t)
  :: Sync.t | {:error, atom}
  defp handle_sync(%HTTPotion.ErrorResponse{message: message}), do: {:error, message}
  defp handle_sync(%HTTPotion.Response{body: body, headers: _headers, status_code: 200}) do
    with {:ok, map} <- Poison.decode(body),
    do: Sync.create!(map) |> put_stuff
  end

  @spec put_stuff(Sync.t | any) :: Sync.t | {:error, :bad_sync}
  def put_stuff(%Sync{} = stuff), do: GenServer.call(__MODULE__, {:stuff, stuff})
  def put_stuff(_), do: {:error, :bad_sync}

  @doc """
    Gets the entire bundle of syncables. This should not be used except for
    debugging.
  """
  @spec fetch_all :: Sync.t
  def fetch_all do
    GenServer.call(__MODULE__, :fetch_all)
  end

  @doc """
    Gets a sequence by it's id.
  """
  @spec get_sequence(integer) :: Sequence.t
  def get_sequence(id) when is_integer(id) do
    GenServer.call(__MODULE__, {:get_sequence, id})
  end

  @doc """
    Gets a list of all the sequences.
  """
  @spec get_sequences :: [Sequence.t]
  def get_sequences do
    GenServer.call(__MODULE__, :get_sequences)
  end

  @doc """
    Gets a regimen by it's id.
  """
  @spec get_regimen(integer) :: Regimen.t
  def get_regimen(id) when is_integer(id) do
    GenServer.call(__MODULE__, {:get_regimen, id})
  end

  @doc """
    Gets a list of all the regimens.
  """
  @spec get_regimens :: [Regimen.t]
  def get_regimens do
    GenServer.call(__MODULE__, :get_regimens)
  end

  @doc """
    Gets a regimen item by it's id.
  """
  @spec get_regimen_item(integer) :: RegimenItem.t
  def get_regimen_item(id) when is_integer(id) do
    GenServer.call(__MODULE__, {:get_regimen_item, id})
  end

  @doc """
    Gets a list of all the regimen items.
  """
  @spec get_regimen_items :: [RegimenItem.t]
  def get_regimen_items do
    GenServer.call(__MODULE__, :get_regimen_items)
  end

  @doc """
    Gets a list of all the Users.
    (This should only ever be one right now.)
  """
  @spec get_users :: [User.t]
  def get_users do
    GenServer.call(__MODULE__, :get_users)
  end
end
