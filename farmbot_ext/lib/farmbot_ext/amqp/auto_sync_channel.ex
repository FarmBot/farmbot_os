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
    Asset.Repo,
    Asset.Device,
    Asset.FbosConfig,
    Asset.FirmwareConfig,
    Asset.FarmwareEnv,
    Asset.FarmwareInstallation,
    JSON
  }

  @exchange "amq.topic"
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
    IO.puts("(*&(*&(*&(*&(*&(*&(*&(*&(*&(**&(*&(*&(*&AMQP.Channel.close(state.chan)))))")
    # If a channel was still open, close it.
    if state.chan, do: AMQP.Channel.close(state.chan)
  end

  def handle_continue(:preload, state) do
    :ok = Preloader.preload_all()
    next_state = %{state | preloaded: true}
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
    device = state.jwt.bot
    data = JSON.decode!(payload)
    label = data["args"]["label"]

    case String.split(key, ".") do
      ["bot", ^device, "sync", asset_kind, id_str] when asset_kind in @known_kinds ->
        asset_kind = Module.concat([Asset, asset_kind])
        id = data["id"] || String.to_integer(id_str)
        params = data["body"]
        handle_asset(asset_kind, label, id, params, state)

      _ ->
        Logger.info("ignoring route: #{key}")
        json = JSON.encode!(%{args: %{label: label}, kind: "rpc_ok"})
        :ok = Basic.publish(state.chan, @exchange, "bot.#{device}.from_device", json)
        {:noreply, state}
    end
  end

  def handle_asset(asset_kind, label, id, params, state) do
    auto_sync? = Asset.fbos_config().auto_sync

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
        Asset.update_fbos_config!(params)
        :ok

      asset_kind == FirmwareConfig ->
        Asset.update_firmware_config!(params)
        :ok

      # TODO(Connor) make this use `sync_group0()`
      asset_kind in [FarmwareEnv, FarmwareInstallation] ->
        asset = Repo.get_by(asset_kind, id: id) || struct(asset_kind)
        changeset = asset_kind.changeset(asset, params)
        Repo.insert_or_update!(changeset)
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

    device = state.jwt.bot
    json = JSON.encode!(%{args: %{label: label}, kind: "rpc_ok"})
    :ok = Basic.publish(state.chan, @exchange, "bot.#{device}.from_device", json)
    {:noreply, state}
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

  def network_status(server \\ __MODULE__) do
    GenServer.call(server, :network_status)
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
end
