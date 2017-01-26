defmodule Farmbot.BotState.ProcessSupervisor do
  @moduledoc """
    Supervises various things
  """

  use Supervisor
  require Logger

  def start_link(), do: Supervisor.start_link(__MODULE__, [], name: __MODULE__)

  def init(_) do
    Logger.debug ">> Starting FarmProcess Supervisor"
    children = [
      worker(Farmbot.BotState.ProcessTracker, [], [restart: :permanent])
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
