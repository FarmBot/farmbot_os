defmodule Farmbot.Repo.Supervisor do
  @moduledoc false

  use Supervisor

  @doc false
  def start_link() do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  @doc false
  def init([]) do
    children = [
      supervisor(Farmbot.Repo, []),
      worker(Farmbot.Repo.Worker, []),
      worker(Farmbot.Asset.Registry, [])
    ]
    supervise(children, [strategy: :one_for_all])
  end
end
