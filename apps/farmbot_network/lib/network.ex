defmodule Farmbot.Network do
  @moduledoc """
    Network Supervisor
  """
  use Supervisor
  require Logger

  @doc """
    Starts the app
  """
  def start(_,args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(target: target) do
    Logger.debug ">> Network init!"
    children = [
      worker(Farmbot.Network.Manager, [target], restart: :permanent)
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  def add_child(mod, args \\ []) do
    Supervisor.start_child(__MODULE__, worker(mod, args, restart: :permanent))
  end
end
