defmodule FarmbotExt.Bootstrap.Supervisor do
  @moduledoc """
  Supervisor responsible for starting all 
  the tasks and processes that require authentication.
  """
  use Supervisor

  @doc false
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl Supervisor
  def init([]) do
    children = [
      FarmbotExt.API.EagerLoader.Supervisor,
      FarmbotExt.API.DirtyWorker.Supervisor,
      FarmbotExt.AMQP.Supervisor,
      FarmbotExt.API.ImageUploader,
      FarmbotExt.Bootstrap.DropPasswordTask
    ]

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
