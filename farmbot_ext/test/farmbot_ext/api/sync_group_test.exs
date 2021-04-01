defmodule FarmbotExt.API.SyncGroupTest do
  require Helpers
  use ExUnit.Case
  alias FarmbotExt.API.SyncGroup

  @all [
    FarmbotCore.Asset.Device,
    FarmbotCore.Asset.FbosConfig,
    FarmbotCore.Asset.FirmwareConfig,
    FarmbotCore.Asset.FarmwareEnv,
    FarmbotCore.Asset.FirstPartyFarmware,
    FarmbotCore.Asset.FarmwareInstallation,
    FarmbotCore.Asset.Peripheral,
    FarmbotCore.Asset.Point,
    FarmbotCore.Asset.SensorReading,
    FarmbotCore.Asset.Sensor,
    FarmbotCore.Asset.Tool,
    FarmbotCore.Asset.Sequence,
    FarmbotCore.Asset.PointGroup,
    FarmbotCore.Asset.Regimen,
    FarmbotCore.Asset.PinBinding,
    FarmbotCore.Asset.FarmEvent
  ]
  test "all_groups" do
    assert SyncGroup.all_groups() == @all
  end
end
