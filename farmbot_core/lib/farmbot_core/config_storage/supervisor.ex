defmodule FarmbotCore.Config.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    Supervisor.init(children(), strategy: :one_for_one)
  end

  def children do
    default = [ {FarmbotCore.Config.Repo, []} ]
    config = Application.get_env(:farmbot_ext, __MODULE__) || []
    Keyword.get(config, :children, default)
  end
end
