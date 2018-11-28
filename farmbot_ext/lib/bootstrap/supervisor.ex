defmodule Farmbot.Bootstrap.Supervisor do
  use Supervisor

  @doc "Start Bootstraped services."
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    children = [
      Farmbot.API.EagerLoader.Supervisor,
      Farmbot.API.DirtyWorker.Supervisor,
      Farmbot.Bootstrap.APITask,
      Farmbot.AMQP.Supervisor,
      Farmbot.API.ImageUploader
    ]

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
