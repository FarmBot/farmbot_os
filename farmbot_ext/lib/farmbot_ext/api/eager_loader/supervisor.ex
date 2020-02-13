defmodule FarmbotExt.API.EagerLoader.Supervisor do
  @moduledoc """
  Responsible for supervising all assets that need to be
  eagerloaded
  """

  use Supervisor
  alias FarmbotExt.API.EagerLoader

  alias FarmbotCore.Asset.{
    Device,
    FarmEvent,
    FarmwareEnv,
    FirstPartyFarmware,
    FarmwareInstallation,
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
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc "Drop all cached assets"
  def drop_all_cache() do
    for {_, pid, _, _} <- Supervisor.which_children(FarmbotExt.API.EagerLoader.Supervisor),
        do: GenServer.cast(pid, :drop)
  end

  @impl Supervisor
  def init(_args) do
    children = [
      {EagerLoader, Device},
      {EagerLoader, FarmEvent},
      {EagerLoader, FarmwareEnv},
      {EagerLoader, FirstPartyFarmware},
      {EagerLoader, FarmwareInstallation},
      {EagerLoader, FbosConfig},
      {EagerLoader, FirmwareConfig},
      {EagerLoader, Peripheral},
      {EagerLoader, PinBinding},
      {EagerLoader, Point},
      {EagerLoader, PointGroup},
      {EagerLoader, Regimen},
      {EagerLoader, SensorReading},
      {EagerLoader, Sensor},
      {EagerLoader, Sequence},
      {EagerLoader, Tool}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
