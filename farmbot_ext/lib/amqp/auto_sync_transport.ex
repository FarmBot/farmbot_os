defmodule Farmbot.AMQP.AutoSyncTransport do
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
    {:ok, _}     = AMQP.Queue.declare(chan, jwt.bot <> "_auto_sync", [auto_delete: false])
    :ok          = AMQP.Queue.bind(chan, jwt.bot <> "_auto_sync", @exchange, [routing_key: "bot.#{jwt.bot}.sync.#"])
    {:ok, _tag}  = Basic.consume(chan, jwt.bot <> "_auto_sync", self(), [no_ack: true])
    {:ok, struct(State, [conn: conn, chan: chan, bot: jwt.bot])}
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
    data = Farmbot.JSON.decode!(payload)
    body = data["body"]
    case asset_kind do
      "FbosConfig" when is_nil(body) ->
        Farmbot.Logger.error 1, "FbosConfig deleted via API?"
      "FbosConfig" ->
        Farmbot.HTTP.SettingsWorker.download_os(data)
      "FirmwareConfig" when is_nil(body) ->
        Farmbot.Logger.error 1, "FirmwareConfig deleted via API?"
      "FirmwareConfig" ->
        Farmbot.HTTP.SettingsWorker.download_firmware(data)
      _ ->
        if !get_config_value(:bool, "settings", "needs_http_sync") do
          id = data["id"] || String.to_integer(id_str)
          # Body might be nil if a resource was deleted.
          body = if body, do: Farmbot.Asset.to_asset(body, asset_kind)
          _cmd = Farmbot.Asset.register_sync_cmd(id, asset_kind, body)
        else
          Logger.warn "not accepting sync_cmd from amqp because bot needs http sync first."
        end
    end

    json = Farmbot.JSON.encode!(%{args: %{label: data["args"]["label"]}, kind: "rpc_ok"})
    :ok = AMQP.Basic.publish state.chan, @exchange, "bot.#{device}.from_device", json
    {:noreply, state}
  end
end
