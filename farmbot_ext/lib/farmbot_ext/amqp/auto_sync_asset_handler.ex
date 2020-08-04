defmodule FarmbotExt.AMQP.AutoSyncAssetHandler do
  require Logger

  alias FarmbotCore.{Asset, BotState, Leds}
  alias FarmbotExt.API.{EagerLoader}

  # Sync messgages about these assets
  # should not be cached. They need to be applied
  # in real time.
  @no_cache_kinds ~w(
    Device
    FbosConfig
    FirmwareConfig
    FarmwareEnv
    FarmwareInstallation
  )

  def handle_asset(asset_kind, id, params) do
    :ok = BotState.set_sync_status("syncing")
    _ = Leds.green(:really_fast_blink)
    Asset.Command.update(asset_kind, id, params)
    :ok = BotState.set_sync_status("synced")
    _ = Leds.green(:solid)
  end

  def cache_sync(kind, id, params) when kind in @no_cache_kinds do
    :ok = Asset.Command.update(kind, id, params)
  end

  def cache_sync(_, _, nil) do
    :ok = BotState.set_sync_status("sync_now")
    _ = Leds.green(:slow_blink)
  end

  def cache_sync(asset_kind, id, params) do
    Logger.info("Autocaching sync #{asset_kind} #{id} #{inspect(params)}")
    changeset = Asset.Command.new_changeset(asset_kind, id, params)
    :ok = EagerLoader.cache(changeset)
    :ok = BotState.set_sync_status("sync_now")
    _ = Leds.green(:slow_blink)
  end
end
