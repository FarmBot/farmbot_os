defmodule Farmbot.FarmEvent.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    children = [
      # worker(Farmbot.FarmEvent.Manager, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
