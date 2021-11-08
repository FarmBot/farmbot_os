defmodule FarmbotOS.Bootstrap.Supervisor do
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
    config = Application.get_env(:farmbot, __MODULE__) || []

    Keyword.get(config, :children, [
      FarmbotOS.EagerLoader.Supervisor,
      FarmbotOS.DirtyWorker.Supervisor,
      FarmbotOS.MQTT.Supervisor,
      FarmbotOS.API.ImageUploader,
      FarmbotOS.Bootstrap.DropPasswordTask,
      FarmbotOS.API.Ping
    ])
  end
end
