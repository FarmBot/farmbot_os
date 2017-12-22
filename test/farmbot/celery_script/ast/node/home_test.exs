defmodule Farmbot.CeleryScript.AST.Node.HomeTest do
  alias Farmbot.CeleryScript.AST.Node.Home

  use FarmbotTestSupport.AST.NodeTestCase, async: false

  setup env do
    Farmbot.Firmware.move_absolute(%Farmbot.Firmware.Vec3{x: 100, y: 100, z: 100}, 100, 100, 100)
    env
  end

  test "mutates env", %{env: env} do
    {:ok, env} = Home.execute(%{axis: :all, speed: 100}, [], env)
    assert_cs_env_mutation(Home, env)
  end

  test "homes all axises", %{env: env} do
    Home.execute(%{axis: :all, speed: 100}, [], env) |> assert_cs_success()
    assert match?(%{x: 0, y: 0, z: 0}, Farmbot.BotState.get_current_pos())
  end

  test "homes x axis", %{env: env} do
    Home.execute(%{axis: :x, speed: 100}, [], env) |> assert_cs_success()
    assert match?(%{x: 0, y: 100, z: 100}, Farmbot.BotState.get_current_pos())
  end

  test "homes y axis", %{env: env} do
    Home.execute(%{axis: :y, speed: 100}, [], env) |> assert_cs_success()
    assert match?(%{y: 0, z: 100, x: 100}, Farmbot.BotState.get_current_pos())
  end

  test "homes z axis", %{env: env} do
    Home.execute(%{axis: :z, speed: 100}, [], env) |> assert_cs_success()
    assert match?(%{z: 0, x: 100, y: 100}, Farmbot.BotState.get_current_pos())
  end
end
