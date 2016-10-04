defmodule SequenceSupervisor do
  def start_link(_args) do
    import Supervisor.Spec
    children = [
      worker(SequenceManager, []),
      worker(SequenceHandler, [], id: 1),
      worker(Sequence, [[]])
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def init(_) do
    {:ok, %{}}
  end
end
