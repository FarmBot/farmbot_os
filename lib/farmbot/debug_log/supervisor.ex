defmodule Farmbot.DebugLog.Supervisor do
  @moduledoc "Internal Logger Supervisor"
  use Supervisor

  def start_link(args, opts) do
    Supervisor.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    children = [
      worker(GenEvent, [name: Farmbot.DebugLog])
      worker(Farmbot.DebugLog, [Farmbot.DebugLog])
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
