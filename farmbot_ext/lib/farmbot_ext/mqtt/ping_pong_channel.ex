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

  require Logger
  require FarmbotCore.Logger
  require FarmbotTelemetry

  defstruct [:parent]
  alias __MODULE__, as: State

  @doc false
  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    state = %State{parent: Keyword.fetch!(args, :parent)}

    {:ok, state}
  end

  def handle_info(_message, state) do
    # routing_key = String.replace(routing_key, "ping", "pong")
    # :ok = Basic.publish(state.chan, @exchange, routing_key, payload)
    {:noreply, state}
  end

  def terminate(r, s) do
    IO.inspect({r, s, "PingPong"})
    raise "TODO"
  end
end
