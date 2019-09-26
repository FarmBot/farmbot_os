defmodule FarmbotOS.SysCalls.PointLookup do
  alias FarmbotCore.Asset
  require Logger

  def point(kind, id) do
    case Asset.get_point(id: id) do
      nil -> {:error, "#{kind} not found"}
      %{x: x, y: y, z: z} -> %{x: x, y: y, z: z}
    end
  end

  def get_toolslot_for_tool(id) do
    with %{id: ^id} <- Asset.get_tool(id: id),
         %{x: x, y: y, z: z} <- Asset.get_point(tool_id: id) do
      %{x: x, y: y, z: z}
    else
      nil -> {:error, "Could not find point for tool by id: #{id}"}
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
end
