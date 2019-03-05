defmodule FarmbotExt.Bootstrap.Supervisor do
  use Supervisor

  @doc "Start Bootstraped services."
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    children = [
      FarmbotExt.API.EagerLoader.Supervisor,
      FarmbotExt.API.DirtyWorker.Supervisor,
      FarmbotExt.Bootstrap.APITask,
      FarmbotExt.AMQP.Supervisor,
      FarmbotExt.API.ImageUploader
    ]

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
