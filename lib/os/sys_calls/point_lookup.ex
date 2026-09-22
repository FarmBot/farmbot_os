defmodule FarmbotOS.SysCalls.PointLookup do
  @moduledoc false

  alias FarmbotOS.Asset
  alias FarmbotOS.SysCalls.Movement

  require Logger

  @relevant_keys [
    :id,
    :tool_id,
    :gantry_mounted,
    :mount_stage,
    :mount_offset_x,
    :mount_offset_y,
    :mount_offset_z,
    :meta,
    :name,
    :openfarm_slug,
    :plant_stage,
    :planted_at,
    :depth,
    :water_curve_id,
    :spread_curve_id,
    :height_curve_id,
    :pointer_type,
    :pullout_direction,
    :resource_id,
    :resource_type,
    :radius,
    :x,
    :y,
    :z
  ]

  def point(kind, id) do
    case Asset.get_point(id: id) do
      nil ->
        {:error, "#{kind || "point"} #{id} not found"}

      %{x: _x, y: _y, z: _z} = s ->
        type = Map.get(s, :pointer_type, kind)

        age =
          if s.planted_at do
            ceil(
              DateTime.diff(
                DateTime.utc_now(),
                s.planted_at || DateTime.utc_now(),
                :second
              ) / 86400
            )
          end

        p =
          %{resource_type: type, resource_id: id}
          |> Map.merge(s)
          |> Map.take(@relevant_keys)
          |> Map.put(:age, age)

        if p.planted_at do
          p
          |> Map.put(:planted_at, DateTime.to_iso8601(s.planted_at))
        else
          p
        end

      other ->
        Logger.debug("Point error: Please notify support #{inspect(other)}")
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
         %{
           name: _name,
           x: _x,
           y: _y,
           z: _z,
           gantry_mounted: _mounted,
           mount_stage: _mount_stage,
           mount_offset_x: _mount_offset_x,
           mount_offset_y: _mount_offset_y,
           mount_offset_z: _mount_offset_z
         } <- p do
      p
      |> Map.take(@relevant_keys)
      |> maybe_adjust_coordinates()
    else
      nil -> {:error, "Could not find point for tool by id: #{id}"}
    end
  end

  defp maybe_adjust_coordinates(point) do
    case mount_stage(point) do
      1 ->
        %{point | x: mounted_coordinate(:x, point.mount_offset_x)}

      2 ->
        %{
          point
          | x: mounted_coordinate(:x, point.mount_offset_x),
            y: mounted_coordinate(:y, point.mount_offset_y)
        }

      3 ->
        %{
          point
          | x: mounted_coordinate(:x, point.mount_offset_x),
            y: mounted_coordinate(:y, point.mount_offset_y),
            z: mounted_coordinate(:z, point.mount_offset_z)
        }

      _ ->
        point
    end
  end

  defp mount_stage(%{mount_stage: stage}) when stage in 1..3, do: stage
  defp mount_stage(%{gantry_mounted: true}), do: 1
  defp mount_stage(_point), do: 0

  defp mounted_coordinate(:x, offset),
    do: Movement.get_current_x() + (offset || 0)

  defp mounted_coordinate(:y, offset),
    do: Movement.get_current_y() + (offset || 0)

  defp mounted_coordinate(:z, offset),
    do: Movement.get_current_z() + (offset || 0)
end
