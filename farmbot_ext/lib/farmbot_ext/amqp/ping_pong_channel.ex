defmodule FarmbotExt.AMQP.PingPongChannel do
  @moduledoc """
  AMQP channel responsible for responding to `ping` messages.
  Simply echos the exact data received on the `ping` channel
  onto the `pong` channel.

  Also has a ~15-20 minute timer that will do an `HTTP` request
  to `/api/device`. This refreshes the `last_seen_api` field which
  is required for devices that have `auto_sync` enabled as with
  that field enabled, the device would never do an HTTP request
  """
  use GenServer
  use AMQP

  alias FarmbotExt.{
    APIFetcher,
    AMQP.Support
  }

  require Logger
  require FarmbotCore.Logger
  require FarmbotTelemetry
  alias FarmbotCore.Leds

  @exchange "amq.topic"

  @lower_bound_ms 900_000
  @upper_bound_ms 1_200_000

  defstruct [:conn, :chan, :jwt, :http_ping_timer, :ping_fails]
  alias __MODULE__, as: State

  @doc false
  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    jwt = Keyword.fetch!(args, :jwt)
    http_ping_timer = Process.send_after(self(), :http_ping, 5000)
    send(self(), :connect_amqp)

    _ = Leds.blue(:off)

    state = %State{
      conn: nil,
      chan: nil,
      jwt: jwt,
      http_ping_timer: http_ping_timer,
      ping_fails: 0
    }

    {:ok, state}
  end

  def terminate(r, s) do
    _ = Leds.blue(:off)
    Support.handle_termination(r, s, "PingPong")
  end

  def handle_info(:connect_amqp, state) do
    bot = state.jwt.bot
    ping = bot <> "_ping"
    route = "bot.#{bot}.ping"

    with {:ok, {conn, chan}} <- Support.create_queue(ping),
         :ok <- Queue.bind(chan, ping, @exchange, routing_key: route <> ".#"),
         {:ok, _tag} <- Basic.consume(chan, ping, self(), no_ack: true) do
      FarmbotTelemetry.event(:amqp, :queue_bind, nil, queue_name: ping, routing_key: route <> ".#")

      FarmbotCore.Logger.debug(3, "connected to PingPong channel")
      _ = Leds.blue(:solid)
      {:noreply, %{state | conn: conn, chan: chan}}
    else
      nil ->
        Process.send_after(self(), :connect_amqp, 5000)
        {:noreply, %{state | conn: nil, chan: nil}}

      err ->
        Support.handle_error(state, err, "PingPong")
    end
  end

  def handle_info(:http_ping, state) do
    ms = Enum.random(@lower_bound_ms..@upper_bound_ms)

    case APIFetcher.get(APIFetcher.client(), "/api/device") do
      {:ok, _} ->
        _ = Leds.blue(:solid)
        http_ping_timer = Process.send_after(self(), :http_ping, ms)
        {:noreply, %{state | http_ping_timer: http_ping_timer, ping_fails: 0}}

      error ->
        ping_fails = state.ping_fails + 1
        FarmbotCore.Logger.error(3, "Ping failed (#{ping_fails}). #{inspect(error)}")
        _ = Leds.blue(:off)
        http_ping_timer = Process.send_after(self(), :http_ping, ms)
        {:noreply, %{state | http_ping_timer: http_ping_timer, ping_fails: ping_fails}}
    end
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, _}, state) do
    {:noreply, state}
  end

  # Sent by the broker when the consumer is
  # unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, _}, state) do
    {:stop, :normal, state}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, _}, state) do
    {:noreply, state}
  end

  def handle_info({:basic_deliver, payload, %{routing_key: routing_key}}, state) do
    routing_key = String.replace(routing_key, "ping", "pong")
    :ok = Basic.publish(state.chan, @exchange, routing_key, payload)
    {:noreply, state}
  end
end
