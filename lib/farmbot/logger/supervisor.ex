defmodule Farmbot.Logger.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      worker(Farmbot.Logger, []),
      worker(Farmbot.Logger.Console, [])
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
