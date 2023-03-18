defmodule FarmbotOS.SysCalls.PointLookup do
  @moduledoc false

  alias FarmbotOS.Asset
  alias FarmbotOS.SysCalls.Movement

  require Logger

  @relevant_keys [
    :id,
    :tool_id,
    :gantry_mounted,
    :meta,
    :name,
    :openfarm_slug,
    :plant_stage,
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

        %{resource_type: type, resource_id: id}
        |> Map.merge(s)
        |> Map.take(@relevant_keys)
        |> Map.put(
          :age,
          div(
            DateTime.diff(
              DateTime.utc_now(),
              s.planted_at || DateTime.utc_now(),
              :second
            ),
            86400
          )
        )

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
         %{name: _name, x: _x, y: _y, z: _z, gantry_mounted: _mounted} <- p do
      p
      |> Map.take(@relevant_keys)
      |> maybe_adjust_coordinates()
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
