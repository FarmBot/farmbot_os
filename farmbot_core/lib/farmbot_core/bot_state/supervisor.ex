defmodule FarmbotCore.BotState.Supervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    Supervisor.init(children(), [strategy: :one_for_all])
  end

  def children do
    default = [
      FarmbotCore.BotState,
      FarmbotCore.BotState.FileSystem,
      FarmbotCore.BotState.SchedulerUsageReporter
    ]
    config = Application.get_env(:farmbot_ext, __MODULE__) || []
    Keyword.get(config, :children, default)
  end
end
