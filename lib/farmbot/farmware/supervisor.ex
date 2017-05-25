defmodule Farmbot.Farmware.Supervisor do
  @moduledoc """
    Supervises Farmware.
  """
  use Farmbot.Context.Supervisor
  alias Farmbot.Farmware

  def init(%Context{} = ctx) do
    children = [
      worker(Farmware.Manager, [ctx, [name: Farmware.Manager]], restart: :permanent)
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
