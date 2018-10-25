defmodule Farmbot.Asset.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    children = [
      Farmbot.Asset.Repo,
      {Farmbot.AssetSupervisor, module: Farmbot.Asset.PersistentRegimen, preload: [:farm_event, :regimen]},
      {Farmbot.AssetSupervisor, module: Farmbot.Asset.FarmEvent},
      {Farmbot.AssetSupervisor, module: Farmbot.Asset.PinBinding},
      {Farmbot.AssetSupervisor, module: Farmbot.Asset.Peripheral},
    ]
    Supervisor.init(children, [strategy: :one_for_one])
  end
end
