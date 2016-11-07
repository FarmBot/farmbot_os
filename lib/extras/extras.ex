defmodule Extras do
  use Supervisor
  def init(_args) do
    children = []
    opts = [strategy: :one_for_one, name: Extras]
    supervise(children, opts)
  end

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end
end
