defmodule BotSync do
  use GenServer
  require Logger
  def init(_args) do
    {:ok, %{token: Auth.fetch_token, resources: %{} }}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def handle_cast(:sync, %{token: token, resources: _old_resources}) do
    server = Map.get(token, "unencoded") |> Map.get("iss")
    auth = Map.get(token, "encoded")

    case HTTPotion.get "#{server}/api/sync",
    [headers: ["Content-Type": "application/json",
               "Authorization": "Bearer " <> auth]] do

     %HTTPotion.Response{body: body,
                         headers: _headers,
                         status_code: 200} ->
       {:noreply, %{token: token, resources: Poison.decode!(body)}}
     error ->
       Logger.debug("Couldn't get resources")
       {:noreply, %{token: token, resources: %{}}}
    end
  end

  def handle_call({:api_request, end_point}, _from, %{token: token, resources: resources}) do
    server = Map.get(token, "unencoded") |> Map.get("iss")
    auth = Map.get(token, "encoded")

    case HTTPotion.get server<>end_point,
    [headers: ["Content-Type": "application/json",
               "Authorization": "Bearer " <> auth]] do

     %HTTPotion.Response{body: body,
                         headers: _headers,
                         status_code: 200} ->
       {:reply, Poison.decode!(body), %{token: token, resources: resources}}
     error -> {:reply, error, %{token: token, resources: resources} }
    end
  end

  def handle_call({:save_sequence, seq}, _from, %{token: token, resources: resources}) do
    new_resources = Map.put(resources, "sequences", [seq | Map.get(resources, "sequences")] )
    {:reply,:ok, %{token: token, resources: new_resources}}
  end

  def handle_call(:fetch, _from, %{token: token, resources: resources}) do
    {:reply, resources, %{token: token, resources: resources}}
  end

  def handle_call({:get_sequence, id}, _from, %{token: token, resources: resources}) do
    sequences = Map.get(resources, "sequences")
    got = Enum.find(sequences, fn(sequence) -> Map.get(sequence, "id") == id end)
    {:reply, got, %{token: token, resources: resources}}
  end

  def handle_call(:get_sequences, _from, %{token: token, resources: resources}) do
    sequences = Map.get(resources, "sequences")
    {:reply, sequences, %{token: token, resources: resources}}
  end

  def handle_call({:get_regimen, id}, _from, %{token: token, resources: resources}) do
    regimens = Map.get(resources, "regimens")
    got = Enum.find(regimens, fn(regimen) -> Map.get(regimen, "id") == id end)
    {:reply, got, %{token: token, resources: resources}}
  end

  def handle_call(:get_regimens, _from, %{token: token, resources: resources}) do
    regimens = Map.get(resources, "regimens")
    {:reply, regimens, %{token: token, resources: resources}}
  end

  def sync do
    GenServer.cast(__MODULE__, :sync)
  end

  def fetch do
    GenServer.call(__MODULE__, :fetch)
  end

  def get_sequence(id) when is_integer(id) do
    GenServer.call(__MODULE__, {:get_sequence, id})
  end

  def get_sequences do
    GenServer.call(__MODULE__, :get_sequences)
  end

  def get_regimen(id) when is_integer(id) do
    GenServer.call(__MODULE__, {:get_regimen, id})
  end

  def get_regimens do
    GenServer.call(__MODULE__, :get_regimens)
  end

  def api_request(end_point) do
    GenServer.call(__MODULE__, {:api_request, end_point})
  end

  def save_sequence(seq) do
    GenServer.call(__MODULE__, {:save_sequence, seq})
  end
end
