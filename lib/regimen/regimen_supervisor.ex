defmodule RegimenSupervisor do
  use Supervisor
  def init(_args) do
    children = []
    opts = [name: __MODULE__, strategy: :one_for_one]
    supervise(children, opts)
  end

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end
end
