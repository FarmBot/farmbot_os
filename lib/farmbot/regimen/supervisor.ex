defmodule Farmbot.Regimen.Supervisor do
  @moduledoc false
  use Supervisor

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    children = []
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  def add_child(regimen, time) do
    spec = worker(Farmbot.Regimen.Manager, [regimen, time], [restart: :transient, id: regimen.id])
    Supervisor.start_child(__MODULE__, spec)
  end

  def remove_child(regimen) do
    Supervisor.terminate_child(__MODULE__, regimen.id)
    Supervisor.delete_child(__MODULE__, regimen.id)
  end
end
