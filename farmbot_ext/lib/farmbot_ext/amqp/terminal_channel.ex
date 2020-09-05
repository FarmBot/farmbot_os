defmodule FarmbotExt.AMQP.TerminalChannel do
  use GenServer
  use AMQP
  require Logger
  require FarmbotTelemetry
  require FarmbotCore.Logger
  alias FarmbotExt.AMQP.ConnectionWorker
  @exchange "amq.topic"

  defstruct [:conn, :chan, :jwt]
  alias __MODULE__, as: State

  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    send(self(), :connect_amqp)

    {:ok, %State{conn: nil, chan: nil, jwt: Keyword.fetch!(args, :jwt)}}
  end

  def handle_info(:connect_amqp, state) do
    with %{} = conn <- ConnectionWorker.connection(),
         {:ok, %{pid: channel_pid} = chan} <- Channel.open(conn),
         Process.link(channel_pid),
         :ok <- Basic.qos(chan, global: true),
         {:ok, _} <- Queue.declare(chan, state.jwt.bot <> "_ping", auto_delete: true),
         {:ok, _} <- Queue.purge(chan, state.jwt.bot <> "_ping"),
         :ok <-
           Queue.bind(chan, state.jwt.bot <> "_ping", @exchange,
             routing_key: "bot.device_xyz.ping.#"
           ),
         {:ok, _tag} <- Basic.consume(chan, state.jwt.bot <> "_ping", self(), no_ack: true) do
      FarmbotCore.Logger.debug(3, "connected to Terminal channel")
      {:noreply, %{state | conn: conn, chan: chan}}
    else
      nil ->
        Process.send_after(self(), :connect_amqp, 5000)
        {:noreply, %{state | conn: nil, chan: nil}}

      err ->
        FarmbotCore.Logger.error(1, "Failed to connect to Terminal channel: #{inspect(err)}")
        Process.send_after(self(), :connect_amqp, 2000)
        {:noreply, %{state | conn: nil, chan: nil}}
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
