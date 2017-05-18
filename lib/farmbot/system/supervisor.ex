defmodule Farmbot.System.Supervisor do
  @moduledoc """
    Supervises Platform specific stuff for Farmbot to operate
  """
  use Supervisor
  @redis_config Application.get_all_env(:farmbot)[:redis]
  @target Mix.Project.config()[:target]

  alias Farmbot.System.Network

  def start_link(context, opts) do
    Supervisor.start_link(__MODULE__, context, opts)
  end

  def init(context) do
    children = [
      worker(Farmbot.System.FS, [@target], restart: :permanent),
      worker(Farmbot.System.FS.Worker, [@target], restart: :permanent),
      worker(Farmbot.System.FS.ConfigStorage, [], restart: :permanent),
      worker(Network, [context, @target, [name: Network]], restart: :permanent),
      worker(Farmbot.System.UeventHandler, [], restart: :permanent)
    ] ++ maybe_redis()
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  @spec maybe_redis :: [Supervisor.Spec.spec]
  defp maybe_redis do
     if @redis_config[:server] do
       [worker(Redis.Server, [], restart: :permanent)]
     else
       []
     end
  end
end
