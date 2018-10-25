defmodule Farmbot.AMQP.AutoSyncTransport do
  use GenServer
  use AMQP

  alias AMQP.{
    Channel,
    Queue
  }

  require Farmbot.Logger
  require Logger
  import Farmbot.Config, only: [get_config_value: 3, update_config_value: 4]

  alias Farmbot.{
    API.EagerLoader,
    Asset.Repo,
    JSON
  }

  @exchange "amq.topic"

  defstruct [:conn, :chan, :bot]
  alias __MODULE__, as: State

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([conn, jwt]) do
    Process.flag(:sensitive, true)
    {:ok, chan} = Channel.open(conn)
    :ok = Basic.qos(chan, global: true)
    {:ok, _} = Queue.declare(chan, jwt.bot <> "_auto_sync", auto_delete: false)

    :ok =
      Queue.bind(chan, jwt.bot <> "_auto_sync", @exchange, routing_key: "bot.#{jwt.bot}.sync.#")

    {:ok, _tag} = Basic.consume(chan, jwt.bot <> "_auto_sync", self(), no_ack: true)
    {:ok, struct(State, conn: conn, chan: chan, bot: jwt.bot)}
  end

  def terminate(_reason, _state) do
    update_config_value(:bool, "settings", "needs_http_sync", true)
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

  def handle_info({:basic_deliver, payload, %{routing_key: key}}, state) do
    device = state.bot
    ["bot", ^device, "sync", asset_kind, id_str] = String.split(key, ".")
    asset_kind = Module.concat([Farmbot, Asset, asset_kind])
    data = JSON.decode!(payload)
    params = data["body"] || raise("FIXME delete machine bork")
    id = data["id"] || String.to_integer(id_str)

    asset = Repo.get_by(asset_kind, id: id) || struct(asset_kind)
    changeset = asset_kind.changeset(asset, params)
    :ok = EagerLoader.cache(changeset)

    json = JSON.encode!(%{args: %{label: data["args"]["label"]}, kind: "rpc_ok"})
    :ok = Basic.publish(state.chan, @exchange, "bot.#{device}.from_device", json)
    {:noreply, state}
  end
end
