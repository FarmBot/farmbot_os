defmodule Farmbot.BotState.Supervisor do
  use Supervisor
  require Logger
  def init(_args) do
    children = [
      worker(GenEvent, [[name: :event_manager]], [id: :event_manager]),
      worker(Farmbot.BotState.Monitor, [:event_manager]),
      worker(Farmbot.BotState.Hardware, [[]], [])
    ]
    opts = [strategy: :one_for_one, name: __MODULE__]
    supervise(children, opts)
  end

  def start_link(args) do
    Logger.debug("Starting Farmbot State Tracker")
    Supervisor.start_link(__MODULE__, args)
  end
end
