defmodule FarmbotCore.DepTracker.Supervisor do
  use Supervisor

  alias FarmbotCore.DepTracker

  @moduledoc false

  def start_link(name) do
    Supervisor.start_link(__MODULE__, name)
  end

  @impl true
  def init(name) do
    registry_name = registry_name(name)

    children = [
      {DepTracker.Table, {name, registry_name}},
      {Registry, [keys: :duplicate, name: registry_name]},
      # {DepTracker.Logger, {name, service: :firmware}},
      {DepTracker.Logger, {name, asset: FarmbotCore.Asset.FbosConfig}},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def registry_name(name) do
    Module.concat(DepTracker.Registry, name)
  end
end