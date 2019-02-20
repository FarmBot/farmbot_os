defmodule Farmbot.Asset.Supervisor do
  @moduledoc false
  use Supervisor
  alias Farmbot.{AssetSupervisor, AssetMonitor}

  alias Farmbot.Asset.{
    Repo,
    Device,
    FarmEvent,
    FarmwareEnv,
    FarmwareInstallation,
    FbosConfig,
    PinBinding,
    Peripheral,
    PersistentRegimen
  }

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    children = [
      Repo,
      {AssetSupervisor, module: FbosConfig},
      {AssetSupervisor, module: Device},
      {AssetSupervisor, module: PersistentRegimen},
      {AssetSupervisor, module: FarmEvent},
      {AssetSupervisor, module: PinBinding},
      {AssetSupervisor, module: Peripheral},
      {AssetSupervisor, module: FarmwareInstallation},
      {AssetSupervisor, module: FarmwareEnv},
      AssetMonitor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
