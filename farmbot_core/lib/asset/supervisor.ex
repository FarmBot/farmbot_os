defmodule Farmbot.Asset.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    children = [
      {Farmbot.Asset.Logger,          []},
      {Farmbot.Asset.Repo,            []},
      {Farmbot.Regimen.NameProvider,  []},
      {Farmbot.FarmEvent.Supervisor,  []},
      {Farmbot.Regimen.Supervisor,    []},
      {Farmbot.PinBinding.Supervisor, []},
      {Farmbot.Peripheral.Supervisor, []},
      {Farmbot.Asset.OnStartTask,     []},
    ]
    Supervisor.init(children, [strategy: :one_for_one])
  end
end
