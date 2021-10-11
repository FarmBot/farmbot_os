defmodule FarmbotExt.Bootstrap.Supervisor do
  @moduledoc """
  Supervisor responsible for starting all
  the tasks and processes that require authentication.
  """
  use Supervisor

  @doc false
  def start_link(args, opts \\ [name: __MODULE__]) do
    Supervisor.start_link(__MODULE__, args, opts)
  end

  @impl Supervisor
  def init([]) do
    Supervisor.init(children(), strategy: :one_for_one)
  end

  def children() do
    config = Application.get_env(:farmbot_core, __MODULE__) || []

    Keyword.get(config, :children, [
      FarmbotExt.EagerLoader.Supervisor,
      FarmbotExt.DirtyWorker.Supervisor,
      FarmbotExt.MQTT.Supervisor,
      FarmbotExt.API.ImageUploader,
      FarmbotExt.Bootstrap.DropPasswordTask,
      FarmbotExt.API.Ping
    ])
  end
end
