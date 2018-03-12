defmodule Farmbot.Asset do
  @moduledoc """
  Hello Phoenix.
  """

  alias Farmbot.Asset
  alias Asset.{
    Peripheral,
    Point,
    Sensor,
    Sequence,
    Tool
  }

  import Ecto.Query

  @doc "Get a Peripheral by it's id."
  def get_peripheral_by_id(peripheral_id) do
    repo().one(from p in Peripheral, where: p.id == ^peripheral_id)
  end

  @doc "Get a Sensor by it's id."
  def get_sensor_by_id(sensor_id) do
    repo().one(from s in Sensor, where: s.id == ^sensor_id)
  end

  @doc "Get a Sequence by it's id."
  def get_sequence_by_id(sequence_id) do
    repo().one(from s in Sequence, where: s.id == ^sequence_id)
  end

  @doc "Get a Point by it's id."
  def get_point_by_id(point_id) do
    repo().one(from p in Point, where: p.id == ^point_id)
  end

  @doc "Get a Tool from a Point by `tool_id`."
  def get_point_from_tool(tool_id) do
    repo().one(from p in Point, where: p.tool_id == ^tool_id)
  end

  @doc "Get a tool by it's id."
  def get_tool_by_id(tool_id) do
    repo().one(from t in Tool, where: t.id == ^tool_id)
  end

  defp repo, do: Farmbot.Repo.current_repo()
end
