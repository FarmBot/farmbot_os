defmodule FarmbotExt.MQTT.PingPongChannel do
  @moduledoc """
  MQTT channel responsible for responding to `ping` messages.
  Simply echos the exact data received on the `ping` channel
  onto the `pong` channel.

  Also has a ~15-20 minute timer that will do an `HTTP` request
  to `/api/device`. This refreshes the `last_seen_api` field which
  is required for devices that have `auto_sync` enabled as with
  that field enabled, the device would never do an HTTP request
  """
  use GenServer
  use AMQP

  alias FarmbotExt.APIFetcher

  require Logger
  require FarmbotCore.Logger
  require FarmbotTelemetry

  @lower_bound_ms 900_000
  @upper_bound_ms 1_200_000

  defstruct [:http_ping_timer, :ping_fails, :parent]
  alias __MODULE__, as: State

  @doc false
  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    state = %State{
      parent: Keyword.fetch!(args, :parent),
      http_ping_timer: FarmbotExt.Time.send_after(self(), :http_ping, 5000),
      ping_fails: 0
    }

    {:ok, state}
  end

  def terminate(r, s) do
    IO.inspect({r, s, "PingPong"})
    raise "TODO"
  end

  def handle_info(:http_ping, state) do
    ms = Enum.random(@lower_bound_ms..@upper_bound_ms)

    case APIFetcher.get(APIFetcher.client(), "/api/device") do
      {:ok, _} ->
        http_ping_timer = FarmbotExt.Time.send_after(self(), :http_ping, ms)
        {:noreply, %{state | http_ping_timer: http_ping_timer, ping_fails: 0}}

      error ->
        ping_fails = state.ping_fails + 1
        FarmbotCore.Logger.error(3, "Ping failed (#{ping_fails}). #{inspect(error)}")
        http_ping_timer = FarmbotExt.Time.send_after(self(), :http_ping, ms)
        {:noreply, %{state | http_ping_timer: http_ping_timer, ping_fails: ping_fails}}
    end
  end

  def handle_info({:basic_deliver, _payload, %{routing_key: _routing_key}}, state) do
    # routing_key = String.replace(routing_key, "ping", "pong")
    # :ok = Basic.publish(state.chan, @exchange, routing_key, payload)
    {:noreply, state}
  end
end
