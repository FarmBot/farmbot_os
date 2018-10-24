defmodule Farmbot.Regimen.Supervisor do
  @moduledoc false
  use Supervisor
  alias Farmbot.Asset
  alias Asset.PersistentRegimen
  alias Farmbot.Regimen.NameProvider
  require Farmbot.Logger

  @doc "Stops all running instances of a regimen."
  def stop_all_managers(regimen) do
    Farmbot.Logger.info(3, "Stopping all running regimens by id: #{inspect(regimen.id)}")
    prs = Asset.list_persistent_regimens(regimen)

    for %PersistentRegimen{farm_event_id: feid} <- prs do
      reg_with_fe_id = %{regimen | farm_event_id: feid}
      name = NameProvider.via(reg_with_fe_id)

      case GenServer.whereis(name) do
        nil ->
          Farmbot.Logger.info(3, "Could not find regimen by id: #{reg_with_fe_id.id} and tag: #{feid}")

        regimen_server ->
          GenServer.stop(regimen_server)
      end

      Asset.delete_persistent_regimen(reg_with_fe_id)
    end
  end

  @doc "Looks up all regimen instances that are running, and reindexes them."
  def reindex_all_managers(regimen, time \\ nil) do
    prs = Asset.list_persistent_regimens(regimen)
    Farmbot.Logger.debug(3, "Reindexing #{Enum.count(prs)} running regimens by id: #{regimen.id}")

    for %{farm_event_id: feid} <- prs do
      reg_with_fe_id = %{regimen | farm_event_id: feid}
      name = NameProvider.via(reg_with_fe_id)

      case GenServer.whereis(name) do
        nil ->
          Farmbot.Logger.info(3, "Could not find regimen by id: #{reg_with_fe_id.id} and tag: #{feid}")

        regimen_server ->
          if time do
            Asset.update_persistent_regimen(regimen, %{time: time})
          end

          GenServer.call(regimen_server, {:reindex, reg_with_fe_id, time})
      end
    end
  end

  @doc false
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    prs = Asset.list_persistent_regimens()
    children = build_children(prs)
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  def add_child(regimen, time) do
    regimen.farm_event_id || raise "Starting a regimen process requires a farm event id tag."

    # Farmbot.Logger.debug 3, "Starting regimen: #{regimen.name} #{regimen.farm_event_id} at #{inspect time}"
    Asset.new_persistent_regimen(regimen, time)
    args = [regimen, time]
    opts = [restart: :transient, id: regimen.farm_event_id]
    spec = worker(Farmbot.Regimen.Manager, args, opts)
    Supervisor.start_child(__MODULE__, spec)
  end

  def stop_child(regimen) do
    regimen.farm_event_id || raise "Stopping a regimen process requires a farm event id tag."
    name = NameProvider.via(regimen)

    case GenServer.whereis(name) do
      nil ->
        Farmbot.Logger.info(
          3,
          "Could not find regimen by id: #{regimen.id} and tag: #{regimen.farm_event_id}"
        )

      _regimen_server ->
        Farmbot.Logger.debug(3, "Stopping regimen: #{regimen.name} (#{regimen.farm_event_id})")
        Supervisor.terminate_child(Farmbot.Regimen.Supervisor, regimen.farm_event_id)
        Supervisor.delete_child(Farmbot.Regimen.Supervisor, regimen.farm_event_id)
    end

    Asset.delete_persistent_regimen(regimen)
  end

  @doc "Builds a list of supervisor children. Will also delete and not build a child from stale data."
  @spec build_children([%PersistentRegimen{}]) :: [Supervisor.child_spec()]
  def build_children(prs) do
    Enum.reject(prs, fn %PersistentRegimen{regimen_id: rid, farm_event_id: feid} ->
      raise("FIXME why can this be nil?")
      reg = Asset.get_regimen!(rid, feid)

      if Asset.get_farm_event(feid) && reg do
        _rejected = false
      else
        Farmbot.Logger.debug(
          3,
          "Deleting stale persistent regimen: regimen_id: #{rid} farm_event_id: #{feid}"
        )

        # Build a fake regimen to allow the deletion of the persistent regimen
        # if reg above is nil.
        backup = %Farmbot.Asset.Regimen{
          farm_event_id: feid,
          id: rid,
          name: "Not Real",
          regimen_items: []
        }

        Asset.delete_persistent_regimen(reg || backup)
        _rejected = true
      end
    end)
    |> Enum.map(fn %PersistentRegimen{regimen_id: id, time: time, farm_event_id: feid} ->
      regimen = Asset.get_regimen!(id, feid)
      farm_event = Asset.get_farm_event(feid)
      fe_time = Timex.parse!(farm_event.start_time, "{ISO:Extended}")

      if Timex.compare(fe_time, time) != 0 do
        Asset.update_persistent_regimen(regimen, %{time: fe_time})
        Farmbot.Logger.debug(1, "FarmEvent start time and stored regimen start time are different.")
      end

      args = [regimen, fe_time]
      opts = [restart: :transient, id: feid]
      worker(Farmbot.Regimen.Manager, args, opts)
    end)
  end
end
