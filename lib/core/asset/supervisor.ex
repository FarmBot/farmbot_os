defmodule FarmbotCore.Asset.Supervisor do
  @moduledoc false
  use Supervisor
  alias FarmbotCore.{ChangeSupervisor, AssetMonitor}

  alias FarmbotCore.Asset.{
    Device,
    FarmEvent,
    FarmwareEnv,
    FarmwareInstallation,
    FirstPartyFarmware,
    FbosConfig,
    FirmwareConfig,
    PinBinding,
    PublicKey,
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
      {ChangeSupervisor, module: PublicKey},
      {ChangeSupervisor, module: Peripheral},
      {ChangeSupervisor, module: FirstPartyFarmware},
      {ChangeSupervisor, module: FarmwareInstallation},
      {ChangeSupervisor, module: FarmwareEnv},
      AssetMonitor
    ]
end
