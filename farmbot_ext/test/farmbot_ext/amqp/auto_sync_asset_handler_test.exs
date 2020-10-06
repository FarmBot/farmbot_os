defmodule AutoSyncAssetHandlerTest do
  require Helpers
  use ExUnit.Case, async: false
  use Mimic

  setup :verify_on_exit!
  setup :set_mimic_global

  alias FarmbotExt.AMQP.AutoSyncAssetHandler
  alias FarmbotCore.{Asset, BotState, Leds}

  def auto_sync_on, do: expect(Asset.Query, :auto_sync?, fn -> true end)

  def expect_sync_status_to_be(status),
    do: expect(BotState, :set_sync_status, fn ^status -> :ok end)

  def expect_green_leds(status),
    do: expect(Leds, :green, 1, fn ^status -> :ok end)

  test "handling of deleted assets when auto_sync is enabled" do
    expect_sync_status_to_be("syncing")
    expect_sync_status_to_be("synced")
    expect_green_leds(:really_fast_blink)
    expect_green_leds(:solid)
    AutoSyncAssetHandler.handle_asset("Point", 32, nil)
  end
end
