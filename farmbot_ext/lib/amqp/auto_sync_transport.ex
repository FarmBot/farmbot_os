defmodule Farmbot.AMQP.AutoSyncTransport do
  use GenServer
  use AMQP

  alias AMQP.{
    Channel,
    Queue
  }

  require Logger
  require Farmbot.Logger
  import Farmbot.Config, only: [get_config_value: 3]

  alias Farmbot.{
    API.EagerLoader,
    Asset.Repo,
    Asset.Device,
    Asset.FbosConfig,
    Asset.FirmwareConfig,
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

  def terminate(reason, _state) do
    Logger.error("AutoSync channel crash: #{inspect(reason)}")
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
    device = state.bot

    case String.split(key, ".") do
      ["bot", ^device, "sync", asset_kind, id_str] ->
        asset_kind = Module.concat([Farmbot, Asset, asset_kind])
        data = JSON.decode!(payload)
        id = data["id"] || String.to_integer(id_str)
        params = data["body"]
        label = data["args"]["label"]
        handle_asset(asset_kind, label, id, params, state)

      ["bot", ^device, "nerves_hub"] ->
        handle_nerves_hub(payload, opts, state)
    end
  end

  def handle_asset(asset_kind, label, id, params, state) do
    auto_sync? = get_config_value(:bool, "settings", "auto_sync")

    cond do
      # TODO(Connor) no way to cache a deletion yet
      is_nil(params) && !auto_sync? ->
        :ok

      asset_kind == Device ->
        Repo.get_by!(Device, id: id)
        |> Device.changeset(params)
        |> Repo.update!()
        |> Farmbot.Bootstrap.APITask.device_to_config_storage()

        :ok

      asset_kind == FbosConfig ->
        Repo.get_by!(FbosConfig, id: id)
        |> FbosConfig.changeset(params)
        |> Repo.update!()
        |> Farmbot.Bootstrap.APITask.fbos_config_to_config_storage()

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

    device = state.bot
    json = JSON.encode!(%{args: %{label: label}, kind: "rpc_ok"})
    :ok = Basic.publish(state.chan, @exchange, "bot.#{device}.from_device", json)
    {:noreply, state}
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
