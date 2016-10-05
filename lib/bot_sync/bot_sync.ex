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
     error -> {:fail, error}
    end
  end

  def handle_call(:fetch, _from, %{token: token, resources: resources}) do
    {:reply, resources, %{token: token, resources: resources}}
  end

  def sync do
    GenServer.cast(__MODULE__, :sync)
  end

  def fetch do
    GenServer.call(__MODULE__, :fetch)
  end
end
