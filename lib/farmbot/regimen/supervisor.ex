defmodule Farmbot.Regimen.Supervisor do
  @moduledoc false
  use Supervisor
  alias Farmbot.Asset
  alias Farmbot.System.ConfigStorage
  use Farmbot.Logger

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    prs = ConfigStorage.all_persistent_regimens()
    children = Enum.map(prs, fn(%{regimen_id: id, time: time}) ->
      regimen = Asset.get_regimen_by_id!(id)
      args = [regimen, time]
      opts = [restart: :transient, id: regimen.id]
      worker(Farmbot.Regimen.Manager, args, opts)
    end)
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  def add_child(regimen, time) do
    Logger.debug 3, "Starting regimen: #{regimen.name}"
    args = [regimen, time]
    opts = [restart: :transient, id: regimen.id]
    spec = worker(Farmbot.Regimen.Manager, args, opts)
    case Supervisor.start_child(__MODULE__, spec) do
      {:ok, _} = ok ->
        :ok = ConfigStorage.add_persistent_regimen(regimen, time)
        ok
      er -> er
    end
  end

  def remove_child(regimen) do
    Logger.debug 3, "Stopping regimen: #{regimen.name}"
    Supervisor.terminate_child(__MODULE__, regimen.id)
    Supervisor.delete_child(__MODULE__, regimen.id)
    ConfigStorage.destroy_persistent_regimen(regimen)
  end

  def restart_child(regimen) do
    if pid = Process.whereis(:"regimen-#{regimen.id}") do
      GenServer.call(pid, {:reindex, regimen})
    else
      Logger.error 3, "Regimen: #{regimen.name} doesn't seem to be running."
    end
  end
end
