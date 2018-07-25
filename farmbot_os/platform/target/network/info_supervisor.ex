defmodule Farmbot.Target.Network.InfoSupervisor do
  use GenServer
  alias Farmbot.Config

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    configs = Config.get_all_network_configs()
    children = Enum.map(configs, fn(config) ->
      {Farmbot.Target.Network.InfoWorker, [config]}
    end)
    Supervisor.init(children, [strategy: :one_for_one])
  end
end
