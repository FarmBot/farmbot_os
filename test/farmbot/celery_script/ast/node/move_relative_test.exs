defmodule Farmbot.CeleryScript.AST.Node.MoveRelativeTest do
  alias Farmbot.CeleryScript.AST.Node.{MoveRelative, MoveAbsolute, Coordinate}

  use FarmbotTestSupport.AST.NodeTestCase, async: false

  test "mutates env", %{env: env} do
    {:ok, env} = MoveRelative.execute(%{x: 0, y: 0, z: 0, speed: 100}, [], env)
    assert_cs_env_mutation(MoveAbsolute, env)
  end

  test "moves relatively from a location to another location", %{env: env} do
    {:ok, coordinate, env} = Coordinate.execute(%{x: 0, y: 0, z: 0}, [], env)
    {:ok, env} = MoveAbsolute.execute(%{location: coordinate, offset: nothing(), speed: 100}, [], env)
    MoveRelative.execute(%{x: 100, y: 150, z: 155, speed: 100}, [], env) |> assert_cs_success()
    assert match?(%{x: 100, y: 150, z: 155}, Farmbot.BotState.get_current_pos())
  end
end
