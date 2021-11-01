defmodule FarmbotOS.Celery.InterpolationTest do
  use ExUnit.Case
  alias FarmbotOS.Celery.Interpolation

  test "guess_z_value/2 - base case" do
    soil_points = [
      %{x: 0, y: 0, z: 0},
      %{x: 10, y: 10, z: 10}
    ]

    current_xy = %{x: 4, y: 4}

    actual =
      soil_points
      |> Interpolation.guess_z_value(current_xy)
      |> Float.round(2)

    assert actual == 1.65
  end

  test "guess_z_value/2 - direct match" do
    soil_points = [
      %{x: 0.0, y: 0.0, z: 0.0},
      %{x: 8.0, y: 8.0, z: 8.0},
      %{x: 9.0, y: 9.0, z: 9.0},
      %{x: 10.0, y: 10.0, z: 10.0}
    ]

    current_xy = %{x: 10, y: 10}

    actual =
      soil_points
      |> Interpolation.guess_z_value(current_xy)
      |> Float.round(2)

    assert actual == 10.0
  end
end
