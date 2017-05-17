defmodule Farmbot.Database.Supervisor do
  @moduledoc """
    Database Supervisor
  """
  use Supervisor

  @doc """
    Starts the database supervisor
  """
  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      worker(Farmbot.Database, [name: Farmbot.Database], [restart: :permanent])
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
