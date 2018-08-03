defmodule Farmbot.AMQP.AutoSyncTransport do
  use GenServer
  use AMQP
  require Farmbot.Logger
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
    Farmbot.Registry.subscribe()
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
        pl = %{"api_migrated" => true} |> Farmbot.JSON.encode!()
        Farmbot.HTTP.put!("/api/fbos_config", pl)
        Farmbot.SettingsSync.run()
      "FbosConfig" ->
        Farmbot.SettingsSync.apply_fbos_map(Farmbot.Config.get_config_as_map()["settings"], body)
      "FirmwareConfig" when is_nil(body) -> :ok
      "FirmwareConfig" ->
        Farmbot.SettingsSync.apply_fw_map(Farmbot.Config.get_config_as_map()["hardware_params"], body)
      _ ->
        if !get_config_value(:bool, "settings", "needs_http_sync") do
          id = String.to_integer(id_str)
          body = if body, do: Farmbot.Asset.to_asset(body, asset_kind), else: nil
          _cmd = Farmbot.Asset.register_sync_cmd(id, asset_kind, body)
          if get_config_value(:bool, "settings", "auto_sync") do
            Farmbot.Asset.fragment_sync()
          end
        else
          IO.puts "not accepting sync_cmd from amqp because bot needs http sync first."
        end
    end

    json = Farmbot.JSON.encode!(%{args: %{label: data["args"]["label"]}, kind: "rpc_ok"})
    :ok = AMQP.Basic.publish state.chan, @exchange, "bot.#{device}.from_device", json
    {:noreply, state}
  end

  def handle_info({Farmbot.Registry, {Farmbot.Config, {"settings", "auto_sync", true}}}, state) do
    Farmbot.AutoSyncTask.maybe_auto_sync()
    {:noreply, state}
  end

  def handle_info({Farmbot.Registry, _}, state), do: {:noreply, state}
end
