defmodule FarmbotCore.Logger.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    opts = [strategy: :one_for_all]
    Supervisor.init([FarmbotCore.Logger.Repo], opts)
  end
end
