defmodule FarmbotExt.MQTT.SyncHandler do
  require FarmbotCore.Logger
  require FarmbotTelemetry
  require Logger

  alias FarmbotCore.{BotState, JSON, Leds, Asset}
  alias FarmbotExt.API.{EagerLoader, Preloader}
  alias FarmbotExt.MQTT
  alias __MODULE__, as: State
  defstruct client_id: "NOT_SET", username: "NOT_SET", preloaded: false

  use GenServer

  @known_kinds ~w(
    Device
    FarmEvent
    FarmwareEnv
    FarmwareInstallation
    FbosConfig
    FirmwareConfig
    Peripheral
    PinBinding
    Point
    PointGroup
    Regimen
    Sensor
    Sequence
    Tool
    )

  def start_link(default, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, default, opts)
  end

  def init(opts) do
    send(self(), :preload)

    state = %State{
      client_id: Keyword.fetch!(opts, :client_id),
      username: Keyword.fetch!(opts, :username)
    }

    {:ok, state}
  end

  def handle_info(:preload, state) do
    _ = Leds.green(:really_fast_blink)

    with :ok <- Preloader.preload_all() do
      _ = Leds.green(:solid)
      BotState.set_sync_status("synced")

      {:noreply, %{state | preloaded: true}}
    else
      reason ->
        BotState.set_sync_status("sync_error")
        _ = Leds.green(:slow_blink)
        FarmbotCore.Logger.error(1, "Error preloading. #{inspect(reason)}")
        FarmbotTelemetry.event(:asset_sync, :preload_error, nil, error: inspect(reason))
        FarmbotExt.Time.send_after(self(), :preload, 5000)

        {:noreply, state}
    end
  end

  def handle_info({:inbound, _, _}, %{preloaded: false} = state) do
    send(self(), :preload)
    {:noreply, state}
  end

  def handle_info(
        {:inbound, [_, _, "sync", kind, id_str], json},
        %{preloaded: true} = state
      )
      when kind in @known_kinds do
    data = JSON.decode!(json)
    id = data["id"] || String.to_integer(id_str)
    handle_asset(kind, id, data["body"])
    rpc_reply(state, data["args"]["label"])
    {:noreply, state}
  end

  def handle_info(_other, state) do
    {:noreply, state}
  end

  def rpc_reply(state, label) do
    topic = "bot/#{state.username}/from_device"
    json = JSON.encode!(%{args: %{label: label}, kind: "rpc_ok"})
    MQTT.publish(state.client_id, topic, json)
  end

  def terminate(_reason, _state) do
    try do
      EagerLoader.Supervisor.drop_all_cache()
    catch
      _, _ ->
        :ok
    end
  end

  def handle_asset(asset_kind, id, params) do
    :ok = BotState.set_sync_status("syncing")
    _ = Leds.green(:really_fast_blink)
    Asset.Command.update(asset_kind, id, params)
    :ok = BotState.set_sync_status("synced")
    _ = Leds.green(:solid)
  end
end
