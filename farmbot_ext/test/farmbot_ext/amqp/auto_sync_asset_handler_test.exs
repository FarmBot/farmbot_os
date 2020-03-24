defmodule AutoSyncAssetHandlerTest do
  use ExUnit.Case, async: true
  use Mimic

  setup :verify_on_exit!
  setup :set_mimic_global

  alias FarmbotExt.AMQP.AutoSyncAssetHandler
  alias FarmbotCore.{Asset, BotState, Leds}

  def auto_sync_off, do: expect(Asset.Query, :auto_sync?, fn -> false end)

  def expect_sync_status_to_be(status),
    do: expect(BotState, :set_sync_status, fn ^status -> :ok end)

  def expect_green_leds(status),
    do: expect(Leds, :green, 1, fn ^status -> :ok end)

  test "handling of deleted assets when auto_sync is disabled" do
    auto_sync_off()
    expect_sync_status_to_be("sync_now")
    expect_green_leds(:slow_blink)
    AutoSyncAssetHandler.handle_asset("Point", 23, nil)
  end
end
