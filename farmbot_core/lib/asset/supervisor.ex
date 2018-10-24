defmodule Farmbot.Asset.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    children = [
      Farmbot.Asset.Repo,
      {Farmbot.AssetSupervisor, Farmbot.Asset.PersistentRegimen},
      {Farmbot.AssetSupervisor, Farmbot.Asset.FarmEvent},
      {Farmbot.AssetSupervisor, Farmbot.Asset.PinBinding},
      {Farmbot.AssetSupervisor, Farmbot.Asset.Peripheral},
    ]
    Supervisor.init(children, [strategy: :one_for_one])
  end
end
