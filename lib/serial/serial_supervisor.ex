defmodule SerialSupervisor do
  def start_link(_args) do
    import Supervisor.Spec
    children = [ worker(UartHandler, [[]], restart: :transient) ]
    Supervisor.start_link(children, strategy: :one_for_one, name: SerialSupervisor)
  end

  def init(_) do
    {:ok, %{}}
  end
end
