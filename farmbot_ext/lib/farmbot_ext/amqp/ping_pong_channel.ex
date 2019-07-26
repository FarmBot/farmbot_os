defmodule FarmbotExt.AMQP.PingPongChannel do
  @moduledoc """
  This module provides an AMQP channel for
  auto-sync messages from the FarmBot API.
  SEE:
    https://developer.farm.bot/docs/realtime-updates-auto-sync#section-example-auto-sync-subscriptions
  """
  use GenServer
  use AMQP

  alias FarmbotExt.{API, AMQP.ConnectionWorker}

  require Logger
  require FarmbotCore.Logger
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
    Process.flag(:sensitive, true)
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

  def terminate(reason, state) do
    FarmbotCore.Logger.error(1, "Disconnected from PingPong channel: #{inspect(reason)}")
    # If a channel was still open, close it.
    _ = Leds.blue(:off)
    if state.chan, do: ConnectionWorker.close_channel(state.chan)
  end

  def handle_info(:connect_amqp, state) do
    bot = state.jwt.bot
    ping = bot <> "_ping"
    route = "bot.#{bot}.ping"

    with %{} = conn <- ConnectionWorker.connection(),
         {:ok, %{pid: channel_pid} = chan} <- Channel.open(conn),
         Process.link(channel_pid),
         :ok <- Basic.qos(chan, global: true),
         {:ok, _} <- Queue.declare(chan, ping, auto_delete: true),
         {:ok, _} <- Queue.purge(chan, ping),
         :ok <- Queue.bind(chan, ping, @exchange, routing_key: route <> ".#"),
         {:ok, _tag} <- Basic.consume(chan, ping, self(), no_ack: true) do
      FarmbotCore.Logger.debug(3, "connected to PingPong channel")
      _ = Leds.blue(:solid)
      {:noreply, %{state | conn: conn, chan: chan}}
    else
      nil ->
        Process.send_after(self(), :connect_amqp, 5000)
        {:noreply, %{state | conn: nil, chan: nil}}

      err ->
        FarmbotCore.Logger.error(1, "Failed to connect to PingPong channel: #{inspect(err)}")
        Process.send_after(self(), :connect_amqp, 2000)
        {:noreply, %{state | conn: nil, chan: nil}}
    end
  end

  def handle_info(:http_ping, state) do
    ms = Enum.random(@lower_bound_ms..@upper_bound_ms)

    case API.get(API.client(), "/api/device") do
      {:ok, _} ->
        _ = Leds.blue(:solid)
        http_ping_timer = Process.send_after(self(), :http_ping, ms)
        {:noreply, %{state | http_ping_timer: http_ping_timer, ping_fails: 0}}

      _ ->
        ping_fails = state.ping_fails + 1
        FarmbotCore.Logger.error(3, "Ping failed (#{ping_fails})")
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
