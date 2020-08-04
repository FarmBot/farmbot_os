defmodule AutoSyncAssetHandlerTest do
  require Helpers
  use ExUnit.Case, async: false
  use Mimic

  setup :verify_on_exit!
  setup :set_mimic_global

  alias FarmbotExt.AMQP.AutoSyncAssetHandler
  alias FarmbotCore.{Asset, BotState, Leds}

  import ExUnit.CaptureLog

  def auto_sync_on, do: expect(Asset.Query, :auto_sync?, fn -> true end)

  def expect_sync_status_to_be(status),
    do: expect(BotState, :set_sync_status, fn ^status -> :ok end)

  def expect_green_leds(status),
    do: expect(Leds, :green, 1, fn ^status -> :ok end)

  test "Handles @no_cache_kinds" do
    id = 64
    params = %{}

    kind =
      ~w(Device FbosConfig FirmwareConfig FarmwareEnv FarmwareInstallation)
      |> Enum.shuffle()
      |> Enum.at(0)

    expect(Asset.Command, :update, 1, fn ^kind, ^id, ^params -> :ok end)
    assert :ok = AutoSyncAssetHandler.cache_sync(kind, id, params)
  end

  test "handling of deleted assets when auto_sync is enabled" do
    expect_sync_status_to_be("syncing")
    expect_sync_status_to_be("synced")
    expect_green_leds(:really_fast_blink)
    expect_green_leds(:solid)
    AutoSyncAssetHandler.handle_asset("Point", 32, nil)
  end

  test "cache sync" do
    id = 64
    params = %{}
    kind = "Point"
    # Helpers.expect_log("Autocaching sync #{kind} #{id} #{inspect(params)}")
    changeset = %{ab: :cd}
    changesetfaker = fn ^kind, ^id, ^params -> changeset end
    expect(FarmbotCore.Asset.Command, :new_changeset, 1, changesetfaker)
    expect(FarmbotExt.API.EagerLoader, :cache, 1, fn ^changeset -> :ok end)
    expect_sync_status_to_be("sync_now")
    expect_green_leds(:slow_blink)
    do_it = fn -> AutoSyncAssetHandler.cache_sync(kind, id, params) end
    assert capture_log(do_it) =~ "Autocaching sync Point 64 %{}"
  end
end
