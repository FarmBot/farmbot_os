defmodule Farmbot.CeleryScript.AST.Node.ConfigUpdateTest do
  use FarmbotTestSupport.AST.NodeTestCase, async: false

  test "mutates env", %{env: env} do
    {:ok, env} = ConfigUpdate.execute(%{package: :farmbot_os}, [], env)
    assert_cs_env_mutation(ConfigUpdate, env)
  end
end
