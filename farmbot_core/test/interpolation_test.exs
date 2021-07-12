defmodule FarmbotCeleryScript.InterpolationTest do
  use ExUnit.Case
  alias FarmbotCeleryScript.Interpolation

  test "guess_z_value/2" do
    soil_points = [
      %{x: 0, y: 0, z: 0},
      %{x: 10, y: 10, z: 10}
    ]

    current_xy = %{x: 4, y: 4}

    expected =
      soil_points
      |> Interpolation.guess_z_value(current_xy)
      |> Float.round(2)

    assert expected == 1.65
  end
end
