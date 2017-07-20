defmodule Farmbot.System.Supervisor do
  @moduledoc """
    Supervises Platform specific stuff for Farmbot to operate
  """
  use Supervisor
  @redis_config Application.get_all_env(:farmbot)[:redis]
  @target Mix.Project.config()[:target]
  alias Farmbot.Context

  alias Farmbot.System.Network

  def start_link(%Context{} = context, opts) do
    Supervisor.start_link(__MODULE__, context, opts)
  end

  def init(context) do
    children = [
      worker(Farmbot.System.FS,
        [context, @target, [name: Farmbot.System.FS]]),

      worker(Farmbot.System.FS.Worker,
        [context, @target, [name: Farmbot.System.FS.Worker]]),

      worker(Farmbot.System.FS.ConfigStorage,
        [context,          [name: Farmbot.System.FS.ConfigStorage]]),

      worker(Network,
        [context, @target, [name: Network]]),
      worker(Farmbot.FactoryResetWatcher, [context, Network, []]),

      worker(Farmbot.System.UeventHandler,
        [context, @target, [name: Farmbot.System.UeventHandler]])
    ]
    ++ maybe_redis(context)
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  @spec maybe_redis(Context.t) :: [Supervisor.Spec.spec]
  defp maybe_redis(context) do
     if @redis_config[:server] do
       [worker(Redis.Server, [context, [name: Redis.Server]])]
     else
       []
     end
  end
end
