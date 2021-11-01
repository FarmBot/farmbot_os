defmodule FarmbotOS.API.SyncGroup do
  @moduledoc "Handles dependency ordering."

  alias FarmbotOS.Asset.{
    Device,
    FarmEvent,
    FarmwareEnv,
    FbosConfig,
    FirmwareConfig,
    Peripheral,
    PinBinding,
    Point,
    PointGroup,
    Regimen,
    SensorReading,
    Sensor,
    Sequence,
    Tool
  }

  def all_groups,
    do: group_0() ++ group_1() ++ group_2() ++ group_3() ++ group_4()

  @doc "Assets in Group 0 are required for FarmBot to operate."
  def group_0,
    do: [
      Device,
      FbosConfig,
      FirmwareConfig,
      FarmwareEnv
    ]

  @doc "Group 1 should have no external requirements"
  def group_1,
    do: [
      Peripheral,
      Point,
      SensorReading,
      Sensor,
      Tool
    ]

  @doc "Group 2 relies on assets in Group 1"
  def group_2,
    do: [
      # Requires Peripheral, Point, Sensor, SensorReading, Tool
      Sequence,
      PointGroup
    ]

  @doc "Group 3 relies on assets in Group 2"
  def group_3,
    do: [
      # Requires Sequence
      Regimen,
      # Requires Sequence
      PinBinding
    ]

  @doc "Group 4 relies on assets in Group 3"
  def group_4,
    do: [
      # Requires Regimen and Sequence
      FarmEvent
    ]
end
