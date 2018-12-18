defmodule Farmbot.Asset do
  @moduledoc """
  API for inserting and retrieving assets.
  """

  alias Farmbot.Asset

  alias Asset.{
    Repo,

    Device,
    FarmEvent,
    FarmwareEnv,
    FarmwareInstallation,
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
  import Farmbot.Config, only: [update_config_value: 4]
  require Logger

  defdelegate to_asset(data, kind), to: Farmbot.Asset.Converter

  def fragment_sync(_), do: :ok
  def full_sync(_, _fun), do: :ok

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

  @doc "Get all pin bindings."
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

  @doc "Get a peripheral by it's pin."
  def get_sensor_by_number(number) do
    Repo.one(from(s in Sensor, where: s.pin == ^number))
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
    uses_seq = &match?(^sequence_id, Map.fetch!(&1, "sequence_id"))

    Repo.all(Regimen)
    |> Enum.filter(&Enum.find(Map.fetch!(&1, :regimen_items), uses_seq))
  end

  def get_farm_event_by_id(feid) do
    Repo.one(from(fe in FarmEvent, where: fe.id == ^feid))
  end

  @doc "Clear all data stored in the Asset Repo."
  def clear_all_data do
    # remote assets.
    Repo.delete_all(Device)
    Repo.delete_all(FarmEvent)
    Repo.delete_all(FarmwareEnv)
    Repo.delete_all(FarmwareInstallation)
    Repo.delete_all(Peripheral)
    Repo.delete_all(PinBinding)
    Repo.delete_all(Point)
    Repo.delete_all(Regimen)
    Repo.delete_all(Sensor)
    Repo.delete_all(Sequence)
    Repo.delete_all(Tool)

    # Interanal assets.
    Repo.delete_all(PersistentRegimen)
    Repo.delete_all(SyncCmd)
    :ok
  end
end
