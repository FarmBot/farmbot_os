defmodule SerialSupervisor do
  def start_link(_args) do
    import Supervisor.Spec
    children = [
      worker(SerialMessageManager, []),
      worker(GcodeMessageHandler, [], id: 1), # Consumer
      worker(UartHandler, [[]])
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def init(_) do
    {:ok, %{}}
  end
end
