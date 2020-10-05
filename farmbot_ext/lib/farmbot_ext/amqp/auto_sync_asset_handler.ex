defmodule FarmbotExt.AMQP.AutoSyncAssetHandler do
  require Logger

  alias FarmbotCore.{Asset, BotState, Leds}

  def handle_asset(asset_kind, id, params) do
    :ok = BotState.set_sync_status("syncing")
    _ = Leds.green(:really_fast_blink)
    Asset.Command.update(asset_kind, id, params)
    :ok = BotState.set_sync_status("synced")
    _ = Leds.green(:solid)
  end
end
