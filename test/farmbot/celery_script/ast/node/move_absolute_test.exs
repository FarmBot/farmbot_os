defmodule Farmbot.CeleryScript.AST.Node.MoveAbsoluteTest do
  alias Farmbot.CeleryScript.AST.Node.{Coordinate, MoveAbsolute}

  use FarmbotTestSupport.AST.NodeTestCase, async: false

  test "mutates env", %{env: env} do
    args = %{
      location: nothing(),
      speed: 100,
      offset: nothing()
    }
    {:ok, env} = MoveAbsolute.execute(args, [], env)
    assert_cs_env_mutation(MoveAbsolute, env)
  end

  test "moves to a location with no offset", %{env: env} do
    nothing = nothing()
    {:ok, coordinate, env} = Coordinate.execute(%{x: 100, y: 123, z: -123}, [], env)
    args = %{
      location: coordinate,
      speed: 100,
      offset: nothing
    }
    MoveAbsolute.execute(args, [], env) |> assert_cs_success()
    %{x: res_x, y: res_y, z: res_z} = Farmbot.BotState.get_current_pos()
    assert res_x == coordinate.args.x
    assert res_y == coordinate.args.y
    assert res_z == coordinate.args.z
  end

  test "moves to a location with an offset", %{env: env} do
    {:ok, location, env} = Coordinate.execute(%{x: 0, y: 0, z: 0}, [], env)
    {:ok, offset,   env} = Coordinate.execute(%{x: 100, y: 123, z: -123}, [], env)
    args = %{
      location: location,
      speed: 100,
      offset: offset
    }
    MoveAbsolute.execute(args, [], env) |> assert_cs_success()
    %{x: res_x, y: res_y, z: res_z} = Farmbot.BotState.get_current_pos()
    assert res_x == offset.args.x
    assert res_y == offset.args.y
    assert res_z == offset.args.z
  end

end
