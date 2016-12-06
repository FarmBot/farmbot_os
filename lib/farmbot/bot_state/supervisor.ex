defmodule Farmbot.BotState.Supervisor do
  use Supervisor
  require Logger
  def init(initial_config)
  do
    children = [
      worker(GenEvent, [[name: BotStateEventManager]], [id: BotStateEventManager]),
      worker(Farmbot.BotState.Monitor,       [BotStateEventManager], []),
      worker(Farmbot.BotState.Configuration, [initial_config], []),
      worker(Farmbot.BotState.Hardware,      [[]], []),
      worker(Farmbot.BotState.Authorization, [[]], []),
      worker(Farmbot.BotState.Network,       [[]], [])
    ]
    opts = [strategy: :one_for_one, name: __MODULE__]
    supervise(children, opts)
  end

  def start_link(args) do
    # Log somethingdebug("Starting Farmbot State Tracker")
    sup = Supervisor.start_link(__MODULE__, args)
    Logger.add_backend(Farmbot.Logger)
    sup
  end
end
