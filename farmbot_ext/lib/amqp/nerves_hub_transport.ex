defmodule Farmbot.AMQP.NervesHubTransport do
  use GenServer
  use AMQP

  alias AMQP.{
    Channel,
    Queue
  }

  require Farmbot.Logger
  require Logger
  alias Farmbot.JSON

  alias Farmbot.AMQP.ConnectionWorker

  @exchange "amq.topic"

  defstruct [:conn, :chan, :jwt]
  alias __MODULE__, as: State

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    jwt = Keyword.fetch!(args, :jwt)
    Process.flag(:sensitive, true)
    {:ok, %State{conn: nil, chan: nil, jwt: jwt}, 0}
  end

  def terminate(reason, state) do
    Farmbot.Logger.error(1, "Disconnected from NervesHub AMQP channel: #{inspect(reason)}")
    # If a channel was still open, close it.
    if state.chan, do: AMQP.Channel.close(state.chan)
  end

  def handle_info(:timeout, state) do
    bot = state.jwt.bot
    nerves_hub = bot <> "_nerves_hub"
    route = "bot.#{bot}.nerves_hub"

    with %{} = conn <- ConnectionWorker.connection(),
         {:ok, chan} <- Channel.open(conn),
         :ok <- Basic.qos(chan, global: true),
         {:ok, _} <- Queue.declare(chan, nerves_hub, auto_delete: false, durable: true),
         :ok <- Queue.bind(chan, nerves_hub, @exchange, routing_key: route),
         {:ok, _tag} <- Basic.consume(chan, nerves_hub, self(), []) do
      {:noreply, %{state | conn: conn, chan: chan}}
    else
      nil ->
        {:noreply, %{state | conn: nil, chan: nil}, 5000}

      err ->
        Farmbot.Logger.error(1, "Failed to connect to NervesHub AMQP channel: #{inspect(err)}")
        {:noreply, %{state | conn: nil, chan: nil}, 1000}
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

  def handle_info({:basic_deliver, payload, %{routing_key: key} = opts}, state) do
    device = state.jwt.bot
    ["bot", ^device, "nerves_hub"] = String.split(key, ".")
    handle_nerves_hub(payload, opts, state)
  end

  def handle_nerves_hub(payload, options, state) do
    alias Farmbot.System.NervesHub

    with {:ok, %{"cert" => base64_cert, "key" => base64_key}} <- JSON.decode(payload),
         {:ok, cert} <- Base.decode64(base64_cert),
         {:ok, key} <- Base.decode64(base64_key),
         :ok <- NervesHub.configure_certs(cert, key),
         :ok <- NervesHub.connect() do
      :ok = Basic.ack(state.chan, options[:delivery_tag])
      {:noreply, state}
    else
      {:error, reason} ->
        Logger.error(1, "NervesHub failed to configure. #{inspect(reason)}")
        {:noreply, state}

      :error ->
        Logger.error(1, "NervesHub payload invalid. (base64)")
        {:noreply, state}
    end
  end
end
