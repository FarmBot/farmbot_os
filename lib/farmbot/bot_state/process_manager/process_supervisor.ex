defmodule Farmbot.BotState.ProcessSupervisor do
  @moduledoc """
    Supervises various things
  """

  use Supervisor
  require Logger

  @doc """
    Starts the Farm Procss Supervisor
  """
  @spec start_link :: {:ok, pid}
  def start_link, do: Supervisor.start_link(__MODULE__, [], name: __MODULE__)

  def init([]) do
    Logger.info ">> Starting FarmProcess Supervisor"
    children = [
      worker(Farmbot.BotState.ProcessTracker, [], [restart: :permanent])
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
