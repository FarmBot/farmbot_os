defmodule FarmEvent.Supervisor do
  @moduledoc """
    Supervisor for FarmEvents
  """
  use Supervisor
  def start_link, do: Supervisor.start_link(__MODULE__, [], name: __MODULE__)

  def init(_) do
    children = [
      worker(FarmEvent.DiffHandler, [], [restart: :permanent])
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
