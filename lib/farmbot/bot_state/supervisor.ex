defmodule Farmbot.BotState.Supervisor do
  use Supervisor
  require Logger
  def init(_args) do
    children = [
      worker(GenEvent, [[name: BotStateEventManager]], [id: BotStateEventManager]),
      worker(Farmbot.BotState.Monitor,       [BotStateEventManager], []),
      worker(Farmbot.BotState.Hardware,      [[]], []),
      worker(Farmbot.BotState.Configuration, [[]], []),
      worker(Farmbot.BotState.Authorization, [[]], [])
    ]
    opts = [strategy: :one_for_one, name: __MODULE__]
    supervise(children, opts)
  end

  def start_link(args) do
    Logger.debug("Starting Farmbot State Tracker")
    Supervisor.start_link(__MODULE__, args)
  end
end
