defmodule Farmbot.BotState.ProcessSupervisor do
  @moduledoc """
    Supervises various things
  """

  use Supervisor
  require Logger
  alias Farmbot.Context

  @doc """
    Starts the Farm Procss Supervisor
  """
  def start_link(%Context{} = ctx, opts),
    do: Supervisor.start_link(__MODULE__, ctx, opts)

  def init(ctx) do
    Logger.info ">> Starting FarmProcess Supervisor"
    children = [
      worker(Farmbot.BotState.ProcessTracker,
             [ctx, [name: Farmbot.BotState.ProcessTracker]],
             [restart: :permanent])
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
