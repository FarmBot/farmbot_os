defmodule SequenceSupervisor do
  use Supervisor

  def init(_args) do
    children = [worker(SequenceManager, [[]], restart: :permanent)]
    opts = [strategy: :one_for_all, name: __MODULE__]
    supervise(children, opts)
  end

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end
end
