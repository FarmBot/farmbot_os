defmodule Farmbot.FarmEvent.Supervisor do
  @moduledoc """
    Supervisor for FarmEvents
  """
  use Supervisor
  def start_link(ctx, opts), do: Supervisor.start_link(__MODULE__, ctx, opts)

  def init(context) do
    children = [
      worker(Farmbot.Regimen.Supervisor,
        [context, [name: Farmbot.Regimen.Supervisor ]], [restart: :permanent]),
      worker(Farmbot.FarmEvent.Runner,
        [context, [name: Farmbot.FarmEvent.Runner    ]], [restart: :permanent])
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
