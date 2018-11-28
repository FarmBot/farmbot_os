defmodule Farmbot.AMQP.CeleryScriptTransport do
  use GenServer
  use AMQP

  alias AMQP.{
    Channel,
    Queue
  }

  require Farmbot.Logger
  require Logger

  alias Farmbot.AMQP.ConnectionWorker

  import Farmbot.Config, only: [get_config_value: 3, update_config_value: 4]

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
    Farmbot.Logger.error(1, "Disconnected from CeleryScript channel: #{inspect(reason)}")
    # If a channel was still open, close it.
    if state.chan, do: AMQP.Channel.close(state.chan)
  end

  def handle_info(:timeout, state) do
    bot = state.jwt.bot
    from_clients = bot <> "_from_clients"
    route = "bot.#{bot}.from_clients"

    with %{} = conn <- ConnectionWorker.connection(),
         {:ok, chan} <- Channel.open(conn),
         :ok <- Basic.qos(chan, global: true),
         {:ok, _} <- Queue.declare(chan, from_clients, auto_delete: true),
         {:ok, _} <- Queue.purge(chan, from_clients),
         :ok <- Queue.bind(chan, from_clients, @exchange, routing_key: route),
         {:ok, _tag} <- Basic.consume(chan, from_clients, self(), no_ack: true) do
      {:noreply, %{state | conn: conn, chan: chan}}
    else
      nil ->
        {:noreply, %{state | conn: nil, chan: nil}, 5000}

      err ->
        Farmbot.Logger.error(1, "Failed to connect to CeleryScript channel: #{inspect(err)}")
        {:noreply, %{state | conn: nil, chan: nil}, 1000}
    end
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, _}, state) do
    if get_config_value(:bool, "settings", "log_amqp_connected") do
      Farmbot.Logger.success(1, "Farmbot is up and running!")
      update_config_value(:bool, "settings", "log_amqp_connected", false)
    end

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

  def handle_info({:basic_deliver, payload, %{routing_key: key}}, state) do
    device = state.jwt.bot
    ["bot", ^device, "from_clients"] = String.split(key, ".")

    spawn_link(fn ->
      {_us, _results} = :timer.tc(__MODULE__, :handle_celery_script, [payload, state])
      # IO.puts("#{results.args.label} took: #{us}µs")
    end)

    {:noreply, state}
  end

  @doc false
  def handle_celery_script(payload, state) do
    json = Farmbot.JSON.decode!(payload)
    # IO.inspect(json, label: "RPC_REQUEST")
    Farmbot.Core.CeleryScript.rpc_request(json, fn results_ast ->
      reply = Farmbot.JSON.encode!(results_ast)

      if results_ast.kind == :rpc_error do
        [%{args: %{message: message}}] = results_ast.body
        Logger.error(message)
      end

      AMQP.Basic.publish(state.chan, @exchange, "bot.#{state.jwt.bot}.from_device", reply)
      results_ast
    end)
  end
end
