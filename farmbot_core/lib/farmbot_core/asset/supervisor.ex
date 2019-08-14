defmodule FarmbotCore.Asset.Supervisor do
  @moduledoc false
  use Supervisor
  alias FarmbotCore.{AssetSupervisor, AssetMonitor}

  alias FarmbotCore.Asset.{
    Repo,
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
    children = [
      Repo,
      {AssetSupervisor, module: FbosConfig},
      {AssetSupervisor, module: FirmwareConfig},
      {AssetSupervisor, module: Device},
      {AssetSupervisor, module: RegimenInstance},
      {AssetSupervisor, module: FarmEvent},
      {AssetSupervisor, module: PinBinding},
      {AssetSupervisor, module: PublicKey},
      {AssetSupervisor, module: Peripheral},
      {AssetSupervisor, module: FirstPartyFarmware},
      {AssetSupervisor, module: FarmwareInstallation},
      {AssetSupervisor, module: FarmwareEnv},
      AssetMonitor,
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
