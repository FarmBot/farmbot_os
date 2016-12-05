defmodule RPC.Supervisor do
  use Supervisor
  @transport Application.get_env(:json_rpc, :transport)
  @handler   Application.get_env(:json_rpc, :handler)

  def init(_args) do
    children = [
      worker(RPC.MessageManager, []),
      worker(RPC.MessageHandler, [@handler], name: RPC.MessageHandler),
      worker(@transport, [[]], restart: :permanent),
      # worker(@handler, [[]], restart: :permanent)
    ]
    supervise(children, strategy: :one_for_one, name: __MODULE__)
  end

  def start_link(args), do: Supervisor.start_link(__MODULE__, args)
end
