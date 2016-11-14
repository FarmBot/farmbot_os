defmodule Farmbot.Supervisor do
  require Logger
  use Supervisor

  def init(_args) do
    children = [
      # handles communications between bot and arduino
      supervisor(Farmbot.Serial.Supervisor, [[]], restart: :permanent ),

      # Handle communications betwen bot and api
      worker(Farmbot.Sync, [[]], restart: :permanent ),

      # Just handles Farmbot scheduler stuff.
      worker(Farmbot.Scheduler, [[]], restart: :permanent )
    ]
    opts = [strategy: :one_for_one, name: Farmbot.Supervisor]
    supervise(children, opts)
  end

  def start_link(args) do
    Logger.debug("Starting Controller")
    Supervisor.start_link(__MODULE__, args)
  end
end
