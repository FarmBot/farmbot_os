defmodule Farmbot.Regimen.Supervisor do
  @moduledoc """
    Supervisor for Regimens
  """
  use Supervisor
  @behaviour Farmbot.EventSupervisor
  alias Farmbot.Context

  @type supervisor :: pid | atom

  @doc """
    Start a Regimen Supervisor
  """
  def start_link(%Context{} = context, opts),
    do: Supervisor.start_link(__MODULE__, context, opts)

  def init(_) do
    children = []
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  @doc """
    Add a child to this supervisor
  """
  def add_child(%Context{} = context, regimen, time) do
    Supervisor.start_child(context.regimen_supervisor,
      worker(Farmbot.Regimen.Runner, [context, regimen, time],
        [restart: :permanent, id: regimen.id]))
  end

  @doc """
    Remove a child from this supervisor.
  """
  def remove_child(%Context{} = context, regimen) do
    Supervisor.terminate_child(context.regimen_supervisor, regimen.id)
    Supervisor.delete_child(context.regimen_supervisor, regimen.id)
  end
end
