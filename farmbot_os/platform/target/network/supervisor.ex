defmodule FarmbotOS.Platform.Target.Network.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    children = [
      FarmbotOS.Platform.Target.Network
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
