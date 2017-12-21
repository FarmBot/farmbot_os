defmodule Farmbot.CeleryScript.AST.Node.CoordinateTest do
  alias Farmbot.CeleryScript.AST.Node.Coordinate

  use FarmbotTestSupport.AST.NodeTestCase, async: false


  test "Builds a coordinate", %{env: env} do
    Coordinate.execute(%{x: 100, y: 123, z: -123}, [], env)  |> assert_cs_success(Coordinate)
  end

  test "mutates env", %{env: env} do
    {:ok, _, env} = Coordinate.execute(%{x: 456, y: 999, z: -4000}, [], env)
    assert_cs_env_mutation(Coordinate, env)
  end
end
