defmodule Farmbot.Asset do
  @moduledoc """
  Hello Phoenix.
  """

  alias Farmbot.Asset

  alias Asset.{
    Device,
    FarmEvent,
    Peripheral,
    PinBinding,
    Point,
    Regimen,
    Sensor,
    Sequence,
    Tool
  }

  import Ecto.Query

  def clear_all_data do
    Farmbot.Repo.delete_all(Device)
    Farmbot.Repo.delete_all(FarmEvent)
    Farmbot.Repo.delete_all(Peripheral)
    Farmbot.Repo.delete_all(Point)
    Farmbot.Repo.delete_all(Regimen)
    Farmbot.Repo.delete_all(Sensor)
    Farmbot.Repo.delete_all(Sequence)
    Farmbot.Repo.delete_all(Tool)
    :ok
  end

  def all_pin_bindings do
    Farmbot.Repo.all(PinBinding)
  end

  @doc "Information about _this_ device."
  def device do
    Farmbot.Repo.one(Device)
  end

  @doc "Get a Peripheral by it's id."
  def get_peripheral_by_id(peripheral_id) do
    Farmbot.Repo.one(from(p in Peripheral, where: p.id == ^peripheral_id))
  end

  @doc "Get a Sensor by it's id."
  def get_sensor_by_id(sensor_id) do
    Farmbot.Repo.one(from(s in Sensor, where: s.id == ^sensor_id))
  end

  @doc "Get a Sequence by it's id."
  def get_sequence_by_id(sequence_id) do
    Farmbot.Repo.one(from(s in Sequence, where: s.id == ^sequence_id))
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
    Farmbot.Repo.one(from(p in Point, where: p.id == ^point_id))
  end

  @doc "Get a Tool from a Point by `tool_id`."
  def get_point_from_tool(tool_id) do
    Farmbot.Repo.one(from(p in Point, where: p.tool_id == ^tool_id))
  end

  @doc "Get a Tool by it's id."
  def get_tool_by_id(tool_id) do
    Farmbot.Repo.one(from(t in Tool, where: t.id == ^tool_id))
  end

  @doc "Get a Regimen by it's id."
  def get_regimen_by_id(regimen_id, farm_event_id) do
    reg = Farmbot.Repo.one(from(r in Regimen, where: r.id == ^regimen_id))

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

    Farmbot.Repo.all(Regimen)
    |> Enum.filter(&Enum.find(Map.fetch!(&1, :regimen_items), uses_seq))
  end

  def get_farm_event_by_id(feid) do
    Farmbot.Repo.one(from(fe in FarmEvent, where: fe.id == ^feid))
  end
end
