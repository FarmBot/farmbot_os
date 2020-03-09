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
    Supervisor.init(children(), strategy: :one_for_one)
  end

  # This only exists because I was getting too many crashed
  # supervisor reports in the test suite (distraction from
  # real test failures).
  def children do
    default = [
      FarmbotExt.API.EagerLoader.Supervisor,
      FarmbotExt.API.DirtyWorker.Supervisor,
      FarmbotExt.AMQP.Supervisor,
      FarmbotExt.API.ImageUploader,
      FarmbotExt.Bootstrap.DropPasswordTask
    ]

    config = Application.get_env(:farmbot_ext, __MODULE__) || []
    Keyword.get(config, :children, default)
  end
end
