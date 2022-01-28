defmodule FarmbotOS.Asset.Supervisor do
  @moduledoc false
  use Supervisor
  alias FarmbotOS.{ChangeSupervisor, AssetMonitor}

  alias FarmbotOS.Asset.{
    Device,
    FarmEvent,
    FarmwareEnv,
    FbosConfig,
    FirmwareConfig,
    PinBinding,
    Peripheral,
    RegimenInstance
  }

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    FarmbotOS.LegacyMigrator.run()
    Supervisor.init(children(), strategy: :one_for_one)
  end

  def children,
    do: [
      {ChangeSupervisor, module: FbosConfig},
      {ChangeSupervisor, module: FirmwareConfig},
      {ChangeSupervisor, module: Device},
      {ChangeSupervisor, module: RegimenInstance},
      {ChangeSupervisor, module: FarmEvent},
      {ChangeSupervisor, module: PinBinding},
      {ChangeSupervisor, module: Peripheral},
      {ChangeSupervisor, module: FarmwareEnv},
      AssetMonitor
    ]
end
