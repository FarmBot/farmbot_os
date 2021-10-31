defmodule FarmbotOS.Celery.Interpolation do
  # Given the current X/Y position and a list of soil height samples, provides
  # the current Z coordinate via inverse distance weighting.
  def guess_z_value(soil_points, current_xy) do
    nearest = nearest_neighbor(soil_points, current_xy)

    if nearest.distance == 0 do
      nearest.z
    else
      dividend =
        soil_points
        |> Enum.map(fn p -> 1 / :math.pow(dist(current_xy, p), 4) * p.z end)
        |> Enum.sum()

      divisor =
        soil_points
        |> Enum.map(fn p -> 1 / :math.pow(dist(current_xy, p), 4) end)
        |> Enum.sum()

      Float.round(dividend / divisor, 2)
    end
  end

  defp dist(from, to) do
    x = :math.pow(to.x - from.x, 2)
    y = :math.pow(to.y - from.y, 2)
    :math.pow(x + y, 0.5)
  end

  defp nearest_neighbor(all_points, target_xy) do
    all_points
    |> Enum.map(fn p ->
      %{x: p.x, y: p.y, z: p.z, distance: dist(target_xy, p)}
    end)
    |> Enum.sort_by(fn p -> p.distance end)
    |> Enum.at(0)
  end
end
