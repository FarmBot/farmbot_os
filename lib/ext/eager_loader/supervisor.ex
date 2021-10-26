defmodule FarmbotExt.EagerLoader.Supervisor do
  @moduledoc """
  Responsible for supervising all assets that need to be
  eagerloaded
  """

  use Supervisor
  alias FarmbotExt.EagerLoader

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
    for {_, pid, _, _} <-
          Supervisor.which_children(FarmbotExt.EagerLoader.Supervisor),
        do: GenServer.cast(pid, :drop)
  end

  @impl Supervisor
  def init(_args) do
    Supervisor.init(children(), strategy: :one_for_one)
  end

  def children do
    config = Application.get_env(:farmbot, __MODULE__) || []

    Keyword.get(config, :children, [
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
    ])
  end
end
