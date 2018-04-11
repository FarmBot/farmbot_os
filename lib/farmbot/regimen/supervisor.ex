defmodule Farmbot.Regimen.Supervisor do
  @moduledoc false
  use Supervisor
  alias Farmbot.Asset
  alias Farmbot.System.ConfigStorage
  use Farmbot.Logger
  import Farmbot.Regimen.NameProvider, only: [via: 2]

  def stop_all_managers(regimen) do
    ConfigStorage.persistent_regimens(regimen)
    |> Enum.map(fn(%{time: time}) ->
      server_name = via(regimen, time)
      require IEx; IEx.pry
    end)
  end

  def reindex_all_managers(regimen) do
    ConfigStorage.persistent_regimens(regimen)
    |> Enum.map(fn(%{time: time}) ->
      server_name = via(regimen, time)
      if GenServer.whereis(server_name) do
        GenServer.call(server_name, {:reindex, regimen})
      else
        Logger.warn 2, "#{regimen.name} does not seem to be started."
      end
    end)
  end

  @doc false
  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    prs = ConfigStorage.all_persistent_regimens()
    children = Enum.map(prs, fn(%{regimen_id: id, time: time}) ->
      regimen = Asset.get_regimen_by_id!(id)
      args = [regimen, time]
      opts = [restart: :transient]
      worker(Farmbot.Regimen.Manager, args, opts)
    end)
    opts = [strategy: :one_for_one]
    supervise([worker(Farmbot.Regimen.NameProvider, []) | children], opts)
  end

  def add_child(regimen, time) do
    Logger.debug 3, "Starting regimen: #{regimen.name}"
    args = [regimen, time]
    opts = [restart: :transient]
    spec = worker(Farmbot.Regimen.Manager, args, opts)
    Supervisor.start_child(__MODULE__, spec)
  end
end
