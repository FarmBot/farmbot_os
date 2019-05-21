defmodule FarmbotExt.AMQP.AutoSyncChannel do
  @moduledoc """
  This module provides an AMQP channel for
  auto-sync messages from the FarmBot API.
  SEE:
    https://developer.farm.bot/docs/realtime-updates-auto-sync#section-example-auto-sync-subscriptions
  """
  use GenServer
  use AMQP

  alias FarmbotCore.BotState
  alias FarmbotExt.AMQP.ConnectionWorker
  alias FarmbotExt.API.{Preloader, EagerLoader}

  require Logger
  require FarmbotCore.Logger

  alias FarmbotCore.{
    Asset,
    Asset.Command,
    Asset.Device,
    Asset.FarmwareEnv,
    Asset.FarmwareInstallation,
    Asset.FbosConfig,
    Asset.FirmwareConfig,
    Asset.Query,
    Asset.Repo,
    JSON
  }

  @known_kinds ~w(
    Device
    DiagnosticDump
    FarmEvent
    FarmwareEnv
    FarmwareInstallation
    FbosConfig
    FirmwareConfig
    Peripheral
    PinBinding
    Point
    Regimen
    Sensor
    Sequence
    Tool
  )

  defstruct [:conn, :chan, :jwt, :preloaded]
  alias __MODULE__, as: State

  @doc "Gets the current status of an auto_sync connection"
  def network_status(server \\ __MODULE__) do
    GenServer.call(server, :network_status)
  end

  @doc false
  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    Process.flag(:sensitive, true)
    jwt = Keyword.fetch!(args, :jwt)
    {:ok, %State{conn: nil, chan: nil, jwt: jwt, preloaded: false}, {:continue, :preload}}
  end

  def terminate(reason, state) do
    FarmbotCore.Logger.error(1, "Disconnected from AutoSync channel: #{inspect(reason)}")
    # If a channel was still open, close it.
    if state.chan, do: ConnectionWorker.close_channel(state.chan)
  end

  def handle_continue(:preload, state) do
    :ok = Preloader.preload_all()
    next_state = %{state | preloaded: true}
    :ok = BotState.set_sync_status("synced")
    {:noreply, next_state, {:continue, :connect}}
  end

  def handle_continue(:connect, state) do
    result = ConnectionWorker.maybe_connect(state.jwt.bot)
    compute_reply_from_amqp_state(state, result)
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
    chan = state.chan
    data = JSON.decode!(payload)
    device = state.jwt.bot
    label = data["args"]["label"]
    body = data["body"]

    case String.split(key, ".") do
      ["bot", ^device, "sync", asset_kind, id_str] when asset_kind in @known_kinds ->
        asset_kind = Module.concat([Asset, asset_kind])
        id = data["id"] || String.to_integer(id_str)
        handle_asset(asset_kind, id, body)

      _ ->
        Logger.info("ignoring route: #{key}")
    end

    :ok = ConnectionWorker.rpc_reply(chan, device, label)
    {:noreply, state}
  end

  def handle_asset(asset_kind, id, params) do
    auto_sync? = query().auto_sync?()

    cond do
      # TODO(Connor) no way to cache a deletion yet
      is_nil(params) && !auto_sync? ->
        :ok

      asset_kind == Device ->
        command().update(asset_kind, params)
        :ok

      asset_kind == FbosConfig ->
        Asset.update_fbos_config!(params)
        :ok

      asset_kind == FirmwareConfig ->
        Asset.update_firmware_config!(params)
        :ok

      # TODO(Connor) make this use `sync_group0()`
      asset_kind == FarmwareEnv ->
        Asset.upsert_farmware_env_by_id(id, params)
        :ok

      # TODO(Connor) make this use `sync_group0()`
      asset_kind == FarmwareInstallation ->
        Asset.upsert_farmware_manifest_by_id(id, params)
        :ok

      is_nil(params) && auto_sync? ->
        old = Repo.get_by(asset_kind, id: id)
        old && Repo.delete!(old)
        :ok

      auto_sync? ->
        case Repo.get_by(asset_kind, id: id) do
          nil ->
            struct(asset_kind)
            |> asset_kind.changeset(params)
            |> Repo.insert!()

          asset ->
            asset_kind.changeset(asset, params)
            |> Repo.update!()
        end

        :ok

      true ->
        asset = Repo.get_by(asset_kind, id: id) || struct(asset_kind)
        changeset = asset_kind.changeset(asset, params)
        :ok = EagerLoader.cache(changeset)
        :ok = BotState.set_sync_status("sync_now")
    end
  end

  def handle_call(:network_status, _, state) do
    {
      :reply,
      %{
        conn: Map.fetch!(state, :conn),
        chan: Map.fetch!(state, :chan),
        preloaded: Map.fetch!(state, :preloaded)
      },
      state
    }
  end

  def handle_asset(asset_kind, id, params) do
    auto_sync? = query().auto_sync?()

    if auto_sync? do
      :ok = BotState.set_sync_status("syncing")
      auto_sync(asset_kind, id, params)
      :ok = BotState.set_sync_status("synced")
    else
      cache_sync(asset_kind, id, params)
    end
  end

  def auto_sync(asset_kind = Device, _id, params) do
    # TODO(Connor) maybe check this value?
    _ = command().update(asset_kind, params)
    :ok
  end

  def auto_sync(FbosConfig, _id, params) do
    _ = Asset.update_fbos_config!(params)
    :ok
  end

  def auto_sync(FirmwareConfig, _id, params) do
    _ = Asset.update_firmware_config!(params)
    :ok
  end

  def auto_sync(FarmwareEnv, id, params) do
    _ = Asset.upsert_farmware_env_by_id(id, params)
    :ok
  end

  def auto_sync(FarmwareInstallation, id, params) do
    _ = Asset.upsert_farmware_env_by_id(id, params)
    :ok
  end

  def auto_sync(asset_kind, id, nil) do
    old = Repo.get_by(asset_kind, id: id)
    old && Repo.delete!(old)
    :ok
  end

  def auto_sync(asset_kind, id, params) do
    Logger.info("autosyncing: #{asset_kind} #{id} #{inspect(params)}")

    case Repo.get_by(asset_kind, id: id) do
      nil ->
        struct(asset_kind)
        |> asset_kind.changeset(params)
        |> Repo.insert!()

      asset ->
        asset_kind.changeset(asset, params)
        |> Repo.update!()
    end

    :ok
  end

  def cache_sync(kind, id, params)
      when kind in [
             Device,
             FbosConfig,
             FirmwareConfig,
             FarmwareEnv,
             FarmwareInstallation
           ] do
    :ok = BotState.set_sync_status("syncing")
    :ok = auto_sync(kind, id, params)
    :ok = BotState.set_sync_status("synced")
  end

  def cache_sync(asset_kind, id, params) do
    Logger.info("Autcaching sync #{asset_kind} #{id} #{inspect(params)}")
    asset = Repo.get_by(asset_kind, id: id) || struct(asset_kind)
    changeset = asset_kind.changeset(asset, params)
    :ok = EagerLoader.cache(changeset)
    :ok = BotState.set_sync_status("sync_now")
  end

  defp compute_reply_from_amqp_state(state, %{conn: conn, chan: chan}) do
    {:noreply, %{state | conn: conn, chan: chan}}
  end

  defp compute_reply_from_amqp_state(state, error) do
    # Run error warning if error not nil
    if error,
      do: FarmbotCore.Logger.error(1, "Failed to connect to AutoSync channel: #{inspect(error)}")

    {:noreply, %{state | conn: nil, chan: nil}}
  end

  defp query() do
    mod = Application.get_env(:farmbot_ext, __MODULE__) || []
    Keyword.get(mod, :query_impl, Asset.Query)
  end

  defp command() do
    mod = Application.get_env(:farmbot_ext, __MODULE__) || []
    Keyword.get(mod, :command_impl, Asset.Command)
  end
end
