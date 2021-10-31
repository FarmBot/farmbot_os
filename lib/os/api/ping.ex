defmodule FarmbotOS.API.Ping do
  @moduledoc """
  a ~15-20 minute timer that will do an `HTTP` request to
  `/api/device`. This refreshes the `last_seen_api` field which
  is required for auto_sync.
  """
  use GenServer

  alias FarmbotOS.APIFetcher

  require FarmbotOS.Logger

  @lower_bound_ms 900_000
  @upper_bound_ms 1_200_000

  defstruct [:timer, :failures]
  alias __MODULE__, as: State

  @doc false
  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(_args) do
    {:ok, %State{timer: ping_after(5000), failures: 0}}
  end

  def handle_info(:ping, state) do
    timer = ping_after(random_ms())
    response = APIFetcher.get(APIFetcher.client(), "/api/device")
    handle_response(response, state, timer)
  end

  def handle_response({:ok, _}, state, timer) do
    {:noreply, %{state | timer: timer, failures: 0}}
  end

  def handle_response(error, state, timer) do
    failures = state.failures + 1
    FarmbotOS.Logger.error(3, "Ping failed. #{inspect(error)}")
    {:noreply, %{state | timer: timer, failures: failures}}
  end

  def random_ms() do
    Enum.random(@lower_bound_ms..@upper_bound_ms)
  end

  def ping_after(ms) do
    FarmbotOS.Time.send_after(self(), :ping, ms)
  end
end
