defmodule Farmbot.Asset.Supervisor do
  @moduledoc false
  use Supervisor
  alias Farmbot.{AssetSupervisor, AssetMonitor}

  alias Farmbot.Asset.{
    Repo,
    PersistentRegimen,
    FarmEvent,
    PinBinding,
    Peripheral,
    FarmwareInstallation
  }

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    children = [
      Repo,
      {AssetSupervisor, module: PersistentRegimen, preload: [:farm_event, :regimen]},
      {AssetSupervisor, module: FarmEvent},
      {AssetSupervisor, module: PinBinding},
      {AssetSupervisor, module: Peripheral},
      {AssetSupervisor, module: FarmwareInstallation},
      AssetMonitor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
