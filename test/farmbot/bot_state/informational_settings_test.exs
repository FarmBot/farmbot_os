defmodule Farmbot.BotState.InformationalSettingsTest do
  @moduledoc "Tests info settings."
  alias Farmbot.BotState.InformationalSettings, as: Settings

  use ExUnit.Case

  @version Mix.Project.config[:version]

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

    assert_raise RuntimeError, "unknown sync status: out_of_syc", fn() ->
      status(:out_of_syc)
    end
  end
end
