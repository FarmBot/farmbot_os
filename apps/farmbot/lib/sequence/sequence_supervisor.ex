defmodule Sequence.Supervisor do
  @moduledoc """
    Supervisor for Sequences
  """
  use Supervisor
  def start_link, do: Supervisor.start_link(__MODULE__, [], name: __MODULE__)

  def init(_) do
    children = []
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  @doc """
    Add a child to this supervisor
  """
  def add_child(sequence, time) do
    Supervisor.start_child(__MODULE__,
      worker(SequenceRunner, [sequence, time], [restart: :permanent, id: sequence.id]))
  end
end
