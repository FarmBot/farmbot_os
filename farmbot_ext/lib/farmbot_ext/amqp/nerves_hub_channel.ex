defmodule FarmbotExt.AMQP.NervesHubChannel do
  use GenServer
  use AMQP

  alias AMQP.{
    Channel,
    Queue
  }

  alias FarmbotCore.JSON
  require FarmbotCore.Logger
  require Logger

  alias FarmbotExt.AMQP.ConnectionWorker

  @exchange "amq.topic"
  @handle_nerves_hub_msg Application.get_env(:farmbot_ext, __MODULE__)[:handle_nerves_hub_msg]
  @handle_nerves_hub_msg ||
    Mix.raise("""
    Please define a function that will handle NervesHub certs.

        config :farmbot_ext, Farmbot.AMQP.NervesHubChannel,
          handle_nerves_hub_msg: SomeModule
    """)

  @doc "Save certs to persistent storage somewhere."
  @callback configure_certs(binary(), binary()) :: :ok | {:error, term()}

  @doc "Connect to NervesHub."
  @callback connect() :: :ok | {:error, term()}

  defstruct [:conn, :chan, :jwt, :key, :cert]
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
    FarmbotCore.Logger.error(1, "Disconnected from NervesHub AMQP channel: #{inspect(reason)}")
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
        FarmbotCore.Logger.error(
          1,
          "Failed to connect to NervesHub AMQP channel: #{inspect(err)}"
        )

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

  def handle_info(:handle_nerves_hub_msg, state) do
    with :ok <- configure_certs(state),
         :ok <- connect(state) do
      {:noreply, state}
    else
      error ->
        FarmbotCore.Logger.error(1, "Failed to connect to OTA Service: #{inspect(error)}")
        Process.send_after(self(), :handle_nerves_hub_msg, 5000)
        {:noreply, state}
    end
  end

  def handle_nerves_hub(payload, options, state) do
    with {:ok, %{"cert" => base64_cert, "key" => base64_key}} <- JSON.decode(payload),
         {:ok, cert} <- Base.decode64(base64_cert),
         {:ok, key} <- Base.decode64(base64_key) do
      :ok = Basic.ack(state.chan, options[:delivery_tag])
      send(self(), :handle_nerves_hub_msg)
      {:noreply, %{state | cert: cert, key: key}}
    else
      {:error, reason} ->
        FarmbotCore.Logger.error(1, "OTA Service failed to configure. #{inspect(reason)}")
        {:stop, reason, state}

      :error ->
        FarmbotCore.Logger.error(1, "OTA Service payload invalid. (base64)")
        {:stop, :invalid_payload, state}
    end
  end

  defp handle_nerves_hub_msg,
    do: Application.get_env(:farmbot_ext, __MODULE__)[:handle_nerves_hub_msg]

  defp configure_certs(%{cert: cert, key: key}) do
    try do
      handle_nerves_hub_msg().configure_certs(cert, key)
    catch
      _, reason -> {:error, reason}
    end
  end

  defp connect(_) do
    try do
      handle_nerves_hub_msg().connect()
    catch
      _, reason -> {:error, reason}
    end
  end
end
