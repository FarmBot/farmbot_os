defmodule Farmbot.AMQP.CeleryScriptTransport do
  use GenServer
  use AMQP
  require Farmbot.Logger
  require Logger
  import Farmbot.Config, only: [get_config_value: 3, update_config_value: 4]

  @exchange "amq.topic"

  defstruct [:conn, :chan, :bot]
  alias __MODULE__, as: State

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([conn, jwt]) do
    Process.flag(:sensitive, true)
    {:ok, chan}  = AMQP.Channel.open(conn)
    :ok          = Basic.qos(chan, [global: true])
    {:ok, _}     = AMQP.Queue.declare(chan, jwt.bot <> "_from_clients", [auto_delete: true])
    {:ok, _}     = AMQP.Queue.purge(chan, jwt.bot <> "_from_clients")
    :ok          = AMQP.Queue.bind(chan, jwt.bot <> "_from_clients", @exchange, [routing_key: "bot.#{jwt.bot}.from_clients"])
    {:ok, _tag}  = Basic.consume(chan, jwt.bot <> "_from_clients", self(), [no_ack: true])
    {:ok, struct(State, [conn: conn, chan: chan, bot: jwt.bot])}
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
    device = state.bot
    ["bot", ^device, "from_clients"] = String.split(key, ".")
    handle_celery_script(payload, state)
    {:noreply, state}
  end

  @doc false
  def handle_celery_script(payload, state) do
    json = Farmbot.JSON.decode!(payload)
    IO.inspect(json, label: "RPC_REQUEST")
    Farmbot.CeleryScript.rpc_request(json, fn(results_ast) ->
      reply = Farmbot.JSON.encode!(results_ast)
      if results_ast.kind == :rpc_error do
        [%{args: %{message: message}}] = results_ast.body
        Logger.error(message)
      end
      AMQP.Basic.publish state.chan, @exchange, "bot.#{state.bot}.from_device", reply
    end)
  end
end
