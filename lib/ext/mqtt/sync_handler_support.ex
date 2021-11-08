defmodule FarmbotOS.MQTT.SyncHandlerSupport do
  require FarmbotOS.Logger
  require FarmbotTelemetry
  require Logger

  alias FarmbotOS.{Asset, BotState, JSON, Leds}
  alias FarmbotOS.API.Preloader
  alias FarmbotOS.{MQTT, EagerLoader}

  defstruct client_id: "NOT_SET", username: "NOT_SET", preloaded: false

  def preload_all(state) do
    _ = Leds.green(:really_fast_blink)
    finalize_preload(state, Preloader.preload_all())
  end

  def finalize_preload(state, :ok) do
    _ = Leds.green(:solid)
    BotState.set_sync_status("synced")

    {:noreply, %{state | preloaded: true}}
  end

  def finalize_preload(state, reason) do
    BotState.set_sync_status("sync_error")
    _ = Leds.green(:slow_blink)
    Logger.debug("Error preloading. #{inspect(reason)}")

    FarmbotTelemetry.event(:asset_sync, :preload_error, nil,
      error: inspect(reason)
    )

    FarmbotOS.Time.send_after(self(), :preload, 5000)

    {:noreply, state}
  end

  def handle_asset(asset_kind, id, params) do
    :ok = BotState.set_sync_status("syncing")
    _ = Leds.green(:really_fast_blink)
    Asset.Command.update(asset_kind, id, params)
    :ok = BotState.set_sync_status("synced")
    _ = Leds.green(:solid)
  end

  def drop_all_cache() do
    try do
      EagerLoader.Supervisor.drop_all_cache()
    catch
      _, _ ->
        :ok
    end
  end

  def reply_to_sync_message(state, asset_kind, id_str, json) do
    data = JSON.decode!(json)
    id = data["id"] || String.to_integer(id_str)
    params = data["body"]
    label = data["args"]["label"]
    :ok = BotState.set_sync_status("syncing")
    _ = Leds.green(:really_fast_blink)
    Asset.Command.update(asset_kind, id, params)
    :ok = BotState.set_sync_status("synced")
    _ = Leds.green(:solid)
    topic = "bot/#{state.username}/from_device"
    json = JSON.encode!(%{args: %{label: label}, kind: "rpc_ok"})
    MQTT.publish(state.client_id, topic, json)
  end
end
