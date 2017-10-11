defmodule Farmbot.BotState.InformationalSettingsTest do
  @moduledoc "Tests info settings."
  alias Farmbot.BotState.InformationalSettings, as: Settings

  use ExUnit.Case

  @version Mix.Project.config()[:version]

  setup do
    {:ok, bot_state_tracker} = Farmbot.BotState.start_link()
    {:ok, part} = Settings.start_link(bot_state_tracker, [])
    [info_settings: part]
  end

  test "checks default values" do
    info = %Settings{}
    assert info.controller_version == @version
    assert info.sync_status == :sync_now
  end

  test "checks sync_status enum" do
    import Settings.SyncStatus

    for sts <- [:locked, :maintenance, :sync_error, :sync_now, :synced, :syncing, :unknown] do
      assert status(sts)
    end

    assert_raise RuntimeError, "unknown sync status: out_of_syc", fn ->
      status(:out_of_syc)
    end
  end

  test "sets busy", ctx do
    Settings.set_busy(ctx.info_settings, true)
    assert :sys.get_state(ctx.info_settings).public.busy == true

    Settings.set_busy(ctx.info_settings, false)
    assert :sys.get_state(ctx.info_settings).public.busy == false
  end
end
