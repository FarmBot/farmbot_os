defmodule FarmbotOS.DirtyWorker.Supervisor do
  @moduledoc """
  Responsible for supervising assets that will need to be
  uploaded to the API via a `POST` or `PUT` request.
  """

  use Supervisor
  alias FarmbotOS.DirtyWorker

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

  @doc false
  def start_link(args, opts \\ [name: __MODULE__]) do
    Supervisor.start_link(__MODULE__, args, opts)
  end

  @impl Supervisor
  def init(_args) do
    Supervisor.init(children(), strategy: :one_for_one)
  end

  def children do
    config = Application.get_env(:farmbot, __MODULE__) || []

    Keyword.get(config, :children, [
      {DirtyWorker, Device},
      {DirtyWorker, FbosConfig},
      {DirtyWorker, FirmwareConfig},
      {DirtyWorker, FarmEvent},
      {DirtyWorker, FarmwareEnv},
      {DirtyWorker, Peripheral},
      {DirtyWorker, PinBinding},
      {DirtyWorker, Point},
      {DirtyWorker, PointGroup},
      {DirtyWorker, Regimen},
      {DirtyWorker, SensorReading},
      {DirtyWorker, Sensor},
      {DirtyWorker, Sequence},
      {DirtyWorker, Tool}
    ])
  end
end
