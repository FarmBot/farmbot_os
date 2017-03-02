defmodule Farmbot.Sync.Supervisor do
  @moduledoc """
    Database Supervisor
  """
  use Supervisor

  @doc """
    Starts the database supervisor
  """
  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      worker(Farmbot.Sync.EventManager, [], [restart: :permanent]),
      worker(Farmbot.Sync.Cache, [], [restart: :permanent])
      ] ++ build_children()
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  @spec build_children :: [{:ok, pid}]
  defp build_children do
    syncables = Farmbot.Sync.all_syncables()
    Enum.reduce(syncables, [], fn(module, acc) ->
      diff = Module.concat(module, Diff)
      if Code.ensure_loaded?(diff) do
        item = worker(diff, [], [restart: :permanent])
        [item | acc]
      else
        acc
      end
    end)
  end
end
