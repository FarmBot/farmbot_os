defmodule Farmbot.API.EagerLoader.Supervisor do
  use Supervisor
  alias Farmbot.API.EagerLoader

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
      {EagerLoader, Device},
      {EagerLoader, DiagnosticDump},
      {EagerLoader, FarmEvent},
      {EagerLoader, FarmwareEnv},
      {EagerLoader, FarmwareInstallation},
      {EagerLoader, FbosConfig},
      {EagerLoader, FirmwareConfig},
      {EagerLoader, Peripheral},
      {EagerLoader, PinBinding},
      {EagerLoader, Point},
      {EagerLoader, Regimen},
      {EagerLoader, SensorReading},
      {EagerLoader, Sensor},
      {EagerLoader, Sequence},
      {EagerLoader, Tool}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
