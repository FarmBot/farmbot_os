defmodule Farmbot.System.Supervisor do
  @moduledoc """
    Supervises Platform specific stuff for Farmbot to operate
  """
  use Supervisor

  def start(_, args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(target: target) do
    children = [
      worker(Farmbot.System.FS, [target], restart: :permanent),
      worker(Farmbot.System.FS.Worker, [target], restart: :permanent),
      worker(Farmbot.System.FS.ConfigStorage, [], restart: :permanent),
      worker(Farmbot.System.Network, [target], restart: :permanent)
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
