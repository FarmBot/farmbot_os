defmodule FarmbotCore.Asset.Supervisor do
  @moduledoc false
  use Supervisor
  alias FarmbotCore.{AssetSupervisor, AssetMonitor, EnigmaHandler}

  alias FarmbotCore.Asset.{
    Repo,
    Device,
    FarmEvent,
    FarmwareEnv,
    FarmwareInstallation,
    FbosConfig,
    PinBinding,
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
      {AssetSupervisor, module: Device},
      {AssetSupervisor, module: RegimenInstance},
      {AssetSupervisor, module: FarmEvent},
      {AssetSupervisor, module: PinBinding},
      {AssetSupervisor, module: Peripheral},
      {AssetSupervisor, module: FarmwareInstallation},
      {AssetSupervisor, module: FarmwareEnv},
      AssetMonitor,
      EnigmaHandler,
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
