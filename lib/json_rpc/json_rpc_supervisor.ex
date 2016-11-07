defmodule RPC.Supervisor do
  def start_link(_) do
    import Supervisor.Spec
    children = [
      worker(RPC.MessageManager, []),
      worker(RPC.MessageHandler, [], id: 1, name: RPC.MessageHandler )
    ]
    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end
end
