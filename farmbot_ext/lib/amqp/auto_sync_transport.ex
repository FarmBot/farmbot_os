defmodule Farmbot.AMQP.AutoSyncTransport do
  use GenServer
  use AMQP

  alias AMQP.{
    Channel,
    Queue
  }

  alias Farmbot.AMQP.ConnectionWorker

  require Logger
  require Farmbot.Logger

  alias Farmbot.{
    API.EagerLoader,
    Asset.Repo,
    Asset.Device,
    Asset.FbosConfig,
    Asset.FirmwareConfig,
    JSON
  }

  @exchange "amq.topic"

  defstruct [:conn, :chan, :jwt]
  alias __MODULE__, as: State

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    Process.flag(:sensitive, true)
    jwt = Keyword.fetch!(args, :jwt)
    {:ok, %State{conn: nil, chan: nil, jwt: jwt}, 1000}
  end

  def terminate(reason, state) do
    Farmbot.Logger.error(1, "Disconnected from AutoSync channel: #{inspect(reason)}")
    # If a channel was still open, close it.
    if state.chan, do: AMQP.Channel.close(state.chan)
  end

  def handle_info(:timeout, state) do
    jwt = state.jwt
    bot = jwt.bot
    auto_sync = bot <> "_auto_sync"
    route = "bot.#{bot}.sync.#"

    with %{} = conn <- ConnectionWorker.connection(),
         {:ok, chan} <- Channel.open(conn),
         :ok <- Basic.qos(chan, global: true),
         {:ok, _} <- Queue.declare(chan, auto_sync, auto_delete: false),
         :ok <- Queue.bind(chan, auto_sync, @exchange, routing_key: route),
         {:ok, _} <- Basic.consume(chan, auto_sync, self(), no_ack: true) do
      {:noreply, %{state | conn: conn, chan: chan}}
    else
      nil ->
        {:noreply, %{state | conn: nil, chan: nil}, 5000}

      error ->
        Farmbot.Logger.error(1, "Failed to connect to AutoSync channel: #{inspect(error)}")
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

  def handle_info({:basic_deliver, payload, %{routing_key: key}}, state) do
    device = state.jwt.bot

    case String.split(key, ".") do
      ["bot", ^device, "sync", asset_kind, id_str] ->
        asset_kind = Module.concat([Farmbot, Asset, asset_kind])
        data = JSON.decode!(payload)
        id = data["id"] || String.to_integer(id_str)
        params = data["body"]
        label = data["args"]["label"]
        handle_asset(asset_kind, label, id, params, state)
    end
  end

  def handle_asset(asset_kind, label, id, params, state) do
    auto_sync? = Farmbot.Asset.fbos_config().auto_sync

    cond do
      # TODO(Connor) no way to cache a deletion yet
      is_nil(params) && !auto_sync? ->
        :ok

      asset_kind == Device ->
        Repo.get_by!(Device, id: id)
        |> Device.changeset(params)
        |> Repo.update!()

        :ok

      asset_kind == FbosConfig ->
        Repo.get_by!(FbosConfig, id: id)
        |> FbosConfig.changeset(params)
        |> Repo.update!()

        :ok

      asset_kind == FirmwareConfig ->
        raise("FIXME")

      is_nil(params) && auto_sync? ->
        old = Repo.get_by(asset_kind, id: id)
        old && Repo.delete!(old)
        :ok

      auto_sync? ->
        if Code.ensure_loaded?(asset_kind) do
          case Repo.get_by(asset_kind, id: id) do
            nil ->
              struct(asset_kind)
              |> asset_kind.changeset(params)
              |> Repo.insert!()

            asset ->
              asset_kind.changeset(asset, params)
              |> Repo.update!()
          end
        end

      true ->
        if Code.ensure_loaded?(asset_kind) do
          asset = Repo.get_by(asset_kind, id: id) || struct(asset_kind)
          changeset = asset_kind.changeset(asset, params)
          :ok = EagerLoader.cache(changeset)
        else
          :ok
        end
    end

    device = state.jwt.bot
    json = JSON.encode!(%{args: %{label: label}, kind: "rpc_ok"})
    :ok = Basic.publish(state.chan, @exchange, "bot.#{device}.from_device", json)
    {:noreply, state}
  end
end
