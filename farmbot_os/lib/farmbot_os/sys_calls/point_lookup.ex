defmodule FarmbotOS.SysCalls.PointLookup do
  @moduledoc false

  alias FarmbotCore.Asset
  alias FarmbotOS.SysCalls.Movement

  require Logger

  def point(kind, id) do
    case Asset.get_point(id: id) do
      nil -> {:error, "#{kind} not found"}
      %{name: name, x: x, y: y, z: z} -> %{name: name, x: x, y: y, z: z}
    end
  end

  def get_point_group(id) when is_number(id) do
    case Asset.get_point_group(id: id) do
      nil -> {:error, "Could not find PointGroup.#{id}"}
      %{point_ids: _} = group -> group
    end
  end

  def get_point_group(type) when is_binary(type) do
    Logger.debug("Looking up points by type: #{type}")
    points = Asset.get_all_points_by_type(type)

    Enum.reduce(points, %{point_ids: []}, fn
      %{id: id}, acc -> %{acc | point_ids: [id | acc.point_ids]}
    end)
  end

  def get_toolslot_for_tool(id) do
    tool = Asset.get_tool(id: id)
    p = Asset.get_point(tool_id: id)

    with %{id: ^id} <- tool,
         %{name: name, x: x, y: y, z: z, gantry_mounted: mounted} <- p do
      maybe_adjust_coordinates(%{
        name: name,
        x: x,
        y: y,
        z: z,
        gantry_mounted: mounted
      })
    else
      nil -> {:error, "Could not find point for tool by id: #{id}"}
    end
  end

  defp maybe_adjust_coordinates(%{gantry_mounted: true} = point) do
    %{point | x: Movement.get_current_x()}
  end

  defp maybe_adjust_coordinates(point) do
    point
  end
end
