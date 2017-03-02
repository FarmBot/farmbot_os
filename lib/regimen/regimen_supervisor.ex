defmodule Regimen.Supervisor do
  @moduledoc """
    Supervisor for Regimens
  """
  use Supervisor
  @behaviour Farmbot.EventSupervisor
  def start_link, do: Supervisor.start_link(__MODULE__, [], name: __MODULE__)

  def init(_) do
    children = []
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  @doc """
    Add a child to this supervisor
  """
  def add_child(regimen, time) do
    Supervisor.start_child(__MODULE__,
      worker(RegimenRunner, [regimen, time],
        [restart: :permanent, id: regimen.id]))
  end

  def remove_child(regimen) do
    Supervisor.terminate_child(__MODULE__, regimen.id)
    Supervisor.delete_child(__MODULE__, regimen.id)
  end
end
