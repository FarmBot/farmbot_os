defmodule FarmbotExt.API.Ping do
  @moduledoc """
  a ~15-20 minute timer that will do an `HTTP` request to
  `/api/device`. This refreshes the `last_seen_api` field which
  is required for auto_sync.
  """
  use GenServer

  alias FarmbotExt.APIFetcher

  require FarmbotCore.Logger

  @lower_bound_ms 900_000
  @upper_bound_ms 1_200_000

  defstruct [:http_ping_timer, :ping_fails]
  alias __MODULE__, as: State

  @doc false
  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(_args) do
    state = %State{
      http_ping_timer: FarmbotExt.Time.send_after(self(), :http_ping, 5000),
      ping_fails: 0
    }

    {:ok, state}
  end

  def handle_info(:http_ping, state) do
    ms = Enum.random(@lower_bound_ms..@upper_bound_ms)
    http_ping_timer = FarmbotExt.Time.send_after(self(), :http_ping, ms)

    case APIFetcher.get(APIFetcher.client(), "/api/device") do
      {:ok, _} ->
        {:noreply, %{state | http_ping_timer: http_ping_timer, ping_fails: 0}}

      error ->
        ping_fails = state.ping_fails + 1
        FarmbotCore.Logger.error(3, "Ping failed (#{ping_fails}). #{inspect(error)}")
        {:noreply, %{state | http_ping_timer: http_ping_timer, ping_fails: ping_fails}}
    end
  end
end
