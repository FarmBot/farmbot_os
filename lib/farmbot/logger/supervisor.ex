defmodule Farmbot.Logger.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    children = [
      worker(Farmbot.Logger, []),
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
