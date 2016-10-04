defmodule Controller do
  # use Application
  require Logger
  use Supervisor

  def start_link(_args) do
    import Supervisor.Spec, warn: false
    Logger.debug("Starting Controller")

    children = [
      worker(Auth, [[]]),
      supervisor(RPCSupervisor, [[]],   restart: :permanent ),
      supervisor(BotCommandSupervisor, [[]], restart: :permanent),
      worker(BotStatus, [[]]  ,             restart: :permanent ),
      supervisor(SerialSupervisor, [[]],    restart: :permanent ),
      supervisor(MqttSupervisor, [[]],      restart: :permanent ),
      supervisor(SequenceSupervisor, [[]],  restart: :permanent )
      # worker(BotSync, [[]]  ,             restart: :permanent )
    ]
    opts = [strategy: :one_for_all, name: Controller.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
