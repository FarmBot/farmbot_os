defmodule Farmbot.API.DirtyWorker.Supervisor do
  use Supervisor
  alias Farmbot.API.DirtyWorker

  alias Farmbot.Asset.{
    Device,
    DiagnosticDump,
    FarmEvent,
    FarmwareEnv,
    FarmwareInstallation,
    FbosConfig,
    FirmwareConfig,
    Peripheral,
    PinBinding,
    Point,
    Regimen,
    SensorReading,
    Sensor,
    Sequence,
    Tool
  }

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    children = [
      {DirtyWorker, Device},
      {DirtyWorker, DiagnosticDump},
      {DirtyWorker, FarmEvent},
      {DirtyWorker, FarmwareEnv},
      {DirtyWorker, FarmwareInstallation},
      {DirtyWorker, FbosConfig},
      {DirtyWorker, FirmwareConfig},
      {DirtyWorker, Peripheral},
      {DirtyWorker, PinBinding},
      {DirtyWorker, Point},
      {DirtyWorker, Regimen},
      {DirtyWorker, SensorReading},
      {DirtyWorker, Sensor},
      {DirtyWorker, Sequence},
      {DirtyWorker, Tool}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
