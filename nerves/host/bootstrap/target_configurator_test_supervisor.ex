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
        port: 4000,
        acceptors: 3,
        dispatch: [dispatch()]
      )]
      supervise(children, [strategy: :one_for_one])
  end

  defp dispatch do
    {:_, [
      {"/ws", SocketHandler, []},
      {:_, Plug.Adapters.Cowboy.Handler, {Farmbot.Host.TargetConfiguratorTest, []}}
      ]}
  end
end
