defmodule Farmbot.Asset do
  @moduledoc """
  API for inserting and retrieving assets.
  """

  alias Farmbot.Asset

  alias Asset.{
    Repo,

    Device,
    FarmEvent,
    Peripheral,
    PinBinding,
    Point,
    Regimen,
    Sensor,
    Sequence,
    Tool,

    SyncCmd,
    PersistentRegimen
  }

  alias Repo.Snapshot
  require Farmbot.Logger
  import Ecto.Query
  require Logger

  def fragment_sync(verbosity \\ 1) do
    Farmbot.Logger.busy verbosity, "Syncing"
    Farmbot.Registry.dispatch(__MODULE__, {:sync_status, :syncing})
    all_sync_cmds = all_sync_cmds()

    Repo.transaction fn() ->
      for cmd <- all_sync_cmds do
        apply_sync_cmd(cmd)
      end
    end

    destroy_all_sync_cmds()
    Farmbot.Registry.dispatch(__MODULE__, {:sync_status, :synced})
    Farmbot.Logger.success verbosity, "Synced"
    :ok
  end

  def full_sync(verbosity \\ 1, fetch_fun) do
    Farmbot.Logger.busy verbosity, "Syncing"
    Farmbot.Registry.dispatch(__MODULE__, {:sync_status, :syncing})
    results = try do
      fetch_fun.()
    rescue
      ex ->
        Farmbot.Registry.dispatch(__MODULE__, {:sync_status, :sync_error})
        message = Exception.message(ex)
        Logger.error "Fetching resources failed: #{message}"
        {:error, message}
    end

    case results do
      {:ok, all_sync_cmds} when is_list(all_sync_cmds) ->
        old = Repo.snapshot()
        Repo.transaction fn() ->
          :ok = Farmbot.Asset.clear_all_data()
          for cmd <- all_sync_cmds do
            apply_sync_cmd(cmd, false)
          end
        end
        new = Repo.snapshot()
        diff = Snapshot.diff(old, new)
        dispatch_sync(diff)
        destroy_all_sync_cmds()
        Farmbot.Registry.dispatch(__MODULE__, {:sync_status, :synced})
        Farmbot.Logger.success verbosity, "Synced"
      {:error, reason} when is_binary(reason) ->
        destroy_all_sync_cmds()
        Farmbot.Registry.dispatch(__MODULE__, {:sync_status, :sync_error})
        Farmbot.Logger.error verbosity, "Sync error: #{reason}"
    end

  end

  def apply_sync_cmd(cmd, dispatch_sync \\ true) do
    mod = Module.concat(["Farmbot", "Asset", cmd.kind])
    if Code.ensure_loaded?(mod) do
      Farmbot.Registry.dispatch(__MODULE__, {:sync_status, :syncing})
      old = Repo.snapshot()
      Farmbot.Logger.debug(3, "Syncing #{cmd.kind}")
      try do
        do_apply_sync_cmd(cmd)
      rescue
        e ->
          Farmbot.Logger.error(1, "Error syncing: #{mod}: #{Exception.message(e)}")
      end
      new = Repo.snapshot()
      diff = Snapshot.diff(old, new)
      if dispatch_sync, do: dispatch_sync(diff)
    else
      Farmbot.Logger.warn(3, "Unknown module: #{mod} #{inspect(cmd)}")
    end
    destroy_sync_cmd(cmd)
  end

  defp dispatch_sync(diff) do
    for deletion <- diff.deletions do
      Farmbot.Registry.dispatch(__MODULE__, {:deletion, deletion})
    end

    for update <- diff.updates do
      Farmbot.Registry.dispatch(__MODULE__, {:update, update})
    end

    for addition <- diff.additions do
      Farmbot.Registry.dispatch(__MODULE__, {:addition, addition})
    end

    Farmbot.Registry.dispatch(__MODULE__, {:sync_status, :synced})
  end

  # When `body` is nil, it means an object was deleted.
  def do_apply_sync_cmd(%{body: nil, remote_id: id, kind: kind}) do
    mod = Module.concat(["Farmbot", "Asset", kind])
    case Repo.get(mod, id) do
      nil ->
        :ok

      existing ->
        Repo.delete!(existing)
        :ok
    end
  end

  def do_apply_sync_cmd(%{body: obj, remote_id: id, kind: kind}) do
    not_struct = strip_struct(obj)
    mod = Module.concat(["Farmbot", "Asset", kind])
    # We need to check if this object exists in the database.
    case Repo.get(mod, id) do
      # If it does not, just return the newly created object.
      nil ->
        change = mod.changeset(struct(mod, not_struct), not_struct)
        Repo.insert!(change)
        :ok
      # if there is an existing record, copy the ecto  meta from the old
      # record. This allows `insert_or_update` to work properly.
      existing ->
        existing
        |> Ecto.Changeset.change(not_struct)
        |> Repo.update!()
        :ok
    end
  end

  defp strip_struct(%{__struct__: _, __meta__: _} = struct) do
    Map.from_struct(struct) |> Map.delete(:__meta__)
  end

  defp strip_struct(already_map), do: already_map

  @doc """
  Register a sync message from an external source.
  This is like a snippit of the changes that have happened.
  `sync_cmd`s should only be applied on `sync`ing.
  `sync_cmd`s are _not_ a source of truth for transactions that have been applied.
  Use the `Farmbot.Asset.Registry` for these types of events.
  """
  def register_sync_cmd(remote_id, kind, body) when is_binary(kind) do
    new_sync_cmd(remote_id, kind, body)
    |> SyncCmd.changeset()
    |> Repo.insert!()
  end

  def new_sync_cmd(remote_id, kind, body)
    when is_integer(remote_id) when is_binary(kind) when is_list(body)
  do
    struct(SyncCmd, %{remote_id: remote_id, kind: kind, body: body})
  end

  @doc "Destroy all sync cmds locally."
  def destroy_all_sync_cmds do
    Repo.delete_all(SyncCmd)
  end

  def all_sync_cmds do
    Repo.all(SyncCmd)
  end

  def destroy_sync_cmd(%SyncCmd{id: nil} = cmd), do: {:ok, cmd}
  def destroy_sync_cmd(%SyncCmd{} = cmd) do
    Repo.delete(cmd)
  end

  def all_pin_bindings do
    Repo.all(PinBinding)
  end

  @doc "Get all Persistent Regimens"
  def all_persistent_regimens do
    Repo.all(PersistentRegimen)
  end

  def persistent_regimens(%Regimen{id: id} = _regimen) do
    Repo.all(from pr in PersistentRegimen, where: pr.regimen_id == ^id)
  end

  def persistent_regimen(%Regimen{id: id, farm_event_id: fid} = _regimen) do
    fid || raise "Can't look up persistent regimens without a farm_event id."
    Repo.one(from pr in PersistentRegimen, where: pr.regimen_id == ^id and pr.farm_event_id == ^fid)
  end

  @doc "Add a new Persistent Regimen."
  def add_persistent_regimen(%Regimen{id: id, farm_event_id: fid} = _regimen, time) do
    fid || raise "Can't save persistent regimens without a farm_event id."
    PersistentRegimen.changeset(struct(PersistentRegimen, %{regimen_id: id, time: time, farm_event_id: fid}))
    |> Repo.insert()
  end

  @doc "Delete a persistent_regimen based on it's regimen id and farm_event id."
  def delete_persistent_regimen(%Regimen{id: regimen_id, farm_event_id: fid} = _regimen) do
    fid || raise "cannot delete persistent_regimen without farm_event_id"
    itm = Repo.one(from pr in PersistentRegimen, where: pr.regimen_id == ^regimen_id and pr.farm_event_id == ^fid)
    if itm, do: Repo.delete(itm), else: nil
  end

  def update_persistent_regimen_time(%Regimen{id: _regimen_id, farm_event_id: _fid} = regimen, %DateTime{} = time) do
    pr = persistent_regimen(regimen)
    if pr do
      pr = Ecto.Changeset.change pr, time: time
      Repo.update!(pr)
    else
      nil
    end
  end

  def clear_all_data do
    Repo.delete_all(Device)
    Repo.delete_all(FarmEvent)
    Repo.delete_all(Peripheral)
    Repo.delete_all(PinBinding)
    Repo.delete_all(Point)
    Repo.delete_all(Regimen)
    Repo.delete_all(Sensor)
    Repo.delete_all(Sequence)
    Repo.delete_all(Tool)
    Repo.delete_all(PersistentRegimen)
    Repo.delete_all(SyncCmd)
    :ok
  end

  @doc "Information about _this_ device."
  def device do
    case Repo.all(Device) do
      [device] -> device
      [] -> nil
      devices when is_list(devices) ->
        Repo.delete_all(Device)
        raise "There should only ever be 1 device!"
    end
  end

  @doc "Get a Peripheral by it's id."
  def get_peripheral_by_id(peripheral_id) do
    Repo.one(from(p in Peripheral, where: p.id == ^peripheral_id))
  end

  @doc "Get a peripheral by it's pin."
  def get_peripheral_by_number(number) do
    Repo.one(from(p in Peripheral, where: p.pin == ^number))
  end

  @doc "Get a Sensor by it's id."
  def get_sensor_by_id(sensor_id) do
    Repo.one(from(s in Sensor, where: s.id == ^sensor_id))
  end

  @doc "Get a Sequence by it's id."
  def get_sequence_by_id(sequence_id) do
    Repo.one(from(s in Sequence, where: s.id == ^sequence_id))
  end

  @doc "Same as `get_sequence_by_id/1` but raises if no Sequence is found."
  def get_sequence_by_id!(sequence_id) do
    case get_sequence_by_id(sequence_id) do
      nil -> raise "Could not find sequence by id #{sequence_id}"
      %Sequence{} = seq -> seq
    end
  end

  @doc "Get a Point by it's id."
  def get_point_by_id(point_id) do
    Repo.one(from(p in Point, where: p.id == ^point_id))
  end

  @doc "Get a Tool from a Point by `tool_id`."
  def get_point_from_tool(tool_id) do
    Repo.one(from(p in Point, where: p.tool_id == ^tool_id))
  end

  @doc "Get a Tool by it's id."
  def get_tool_by_id(tool_id) do
    Repo.one(from(t in Tool, where: t.id == ^tool_id))
  end

  @doc "Get a Regimen by it's id."
  def get_regimen_by_id(regimen_id, farm_event_id) do
    reg = Repo.one(from(r in Regimen, where: r.id == ^regimen_id))

    if reg do
      %{reg | farm_event_id: farm_event_id}
    else
      nil
    end
  end

  @doc "Same as `get_regimen_by_id/1` but raises if no Regimen is found."
  def get_regimen_by_id!(regimen_id, farm_event_id) do
    case get_regimen_by_id(regimen_id, farm_event_id) do
      nil -> raise "Could not find regimen by id #{regimen_id}"
      %Regimen{} = reg -> reg
    end
  end

  @doc "Fetches all regimens that use a particular sequence."
  def get_regimens_using_sequence(sequence_id) do
    uses_seq = &match?(^sequence_id, Map.fetch!(&1, :sequence_id))

    Repo.all(Regimen)
    |> Enum.filter(&Enum.find(Map.fetch!(&1, :regimen_items), uses_seq))
  end

  def get_farm_event_by_id(feid) do
    Repo.one(from(fe in FarmEvent, where: fe.id == ^feid))
  end
end
