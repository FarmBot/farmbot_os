defmodule FarmbotCore.Logger.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    opts = [strategy: :one_for_all]
    supervise(children(), opts)
  end

  def children do
    default = [supervisor(FarmbotCore.Logger.Repo, [])]
    config = Application.get_env(:farmbot_ext, __MODULE__) || []
    Keyword.get(config, :children, default)
  end
end
