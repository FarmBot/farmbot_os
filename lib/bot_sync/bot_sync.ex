defmodule BotSync do
  use GenServer
  require Logger
  def init(_args) do
    {:ok, %{token: token, server: server, sequences: [] }}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def handle_cast(:sync, state) do
    resp = HTTPotion.get "#{server}/api/sequences",
    [headers: ["Content-Type": "application/json",
               "Authorization": "Bearer" <> Map.get(state.token, "encoded")]]
    case resp do
      %HTTPotion.ErrorResponse{message: reason} ->
        Logger.debug("Error Fetching sequences: #{inspect reason}")
        {:noreply, Map.update(state, :sequences, [], fn _cur -> [] end)}
      _ ->
        sequences = Poison.decode!(resp.body)
        Logger.debug("Successfully Fetched Sequences")
        {:noreply, Map.update(state, :sequences, [], fn _cur -> sequences end)}
    end
  end

  def handle_call(:sequences, _from, state) do
    {:reply, Map.get(state, :sequences), state}
  end

  def sync do
    GenServer.cast(__MODULE__, :sync)
  end

  def sequences do
    GenServer.call(__MODULE__, :sequences)
  end

  defp token do
    Auth.fetch_token
  end

  defp server do
    Map.get(token, "unencoded")
    |> Map.get("iss")
  end

end
