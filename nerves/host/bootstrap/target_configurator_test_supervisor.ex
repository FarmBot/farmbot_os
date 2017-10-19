defmodule Farmbot.Host.TargetConfiguratorTest.Supervisor do
  use Supervisor

  def start_link(_, opts) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    children = [
      Plug.Adapters.Cowboy.child_spec(
        :http,
        Farmbot.Host.TargetConfiguratorTest,
        [],
        port: 4000
      )]
      supervise(children, [strategy: :one_for_one])
  end
end
