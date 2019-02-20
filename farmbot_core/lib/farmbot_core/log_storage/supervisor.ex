defmodule Farmbot.Logger.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    children = [
      supervisor(Farmbot.Logger.Repo, [])
    ]

    opts = [strategy: :one_for_all]
    supervise(children, opts)
  end
end
