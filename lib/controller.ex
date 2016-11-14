defmodule Controller do
  require Logger
  use Supervisor

  def init(_args) do
    children = [
      # these handle communications between the frontend and bot.
      supervisor(Mqtt.Supervisor, [[]], restart: :permanent ),
      supervisor(RPC.Supervisor, [[]], restart: :permanent ),

      # handles communications between bot and arduino
      supervisor(Serial.Supervisor, [[]], restart: :permanent ),

      # Handle communications betwen bot and api
      worker(Farmbot.Sync, [[]], restart: :permanent ),

      # Just handles Farmbot scheduler stuff.
      worker(Farmbot.Scheduler, [[]], restart: :permanent )
    ]
    opts = [strategy: :one_for_one, name: Controller.Supervisor]
    supervise(children, opts)
  end

  def start_link(args) do
    Logger.debug("Starting Controller")
    Supervisor.start_link(__MODULE__, args)
  end
end
