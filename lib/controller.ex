defmodule Controller do
  # use Application
  require Logger
  use Supervisor

  def init(_args) do
    children = [
      worker(Auth, [[]], restart: :permanent),
      supervisor(MqttSupervisor, [[]], restart: :permanent ),
      supervisor(RPCSupervisor, [[]], restart: :permanent ),
      worker(BotSync, [[]], restart: :permanent ),
      supervisor(SerialSupervisor, [[]], restart: :transient ),
      worker(FarmEventManager, [[]], restart: :permanent)
    ]
    opts = [strategy: :one_for_one, name: Controller.Supervisor]
    supervise(children, opts)
  end

  def start_link(args) do
    Logger.debug("Starting Controller")
    Supervisor.start_link(__MODULE__, args)
  end
end
