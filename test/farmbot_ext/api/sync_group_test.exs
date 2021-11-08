defmodule FarmbotOS.API.SyncGroupTest do
  require Helpers
  use ExUnit.Case
  alias FarmbotOS.API.SyncGroup

  @all [
    FarmbotOS.Asset.Device,
    FarmbotOS.Asset.FbosConfig,
    FarmbotOS.Asset.FirmwareConfig,
    FarmbotOS.Asset.FarmwareEnv,
    FarmbotOS.Asset.Peripheral,
    FarmbotOS.Asset.Point,
    FarmbotOS.Asset.SensorReading,
    FarmbotOS.Asset.Sensor,
    FarmbotOS.Asset.Tool,
    FarmbotOS.Asset.Sequence,
    FarmbotOS.Asset.PointGroup,
    FarmbotOS.Asset.Regimen,
    FarmbotOS.Asset.PinBinding,
    FarmbotOS.Asset.FarmEvent
  ]
  test "all_groups" do
    assert SyncGroup.all_groups() == @all
  end
end
