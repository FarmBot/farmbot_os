defmodule Farmware.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Farmware.Tracker, [])
    ]

    opts = [strategy: :one_for_one, name: Farmware.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
