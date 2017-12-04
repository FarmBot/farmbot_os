defmodule Farmbot.CeleryScript.AST.Node.SetServoAngleTest do
  alias Farmbot.CeleryScript.AST.Node.SetServoAngle

  use FarmbotTestSupport.AST.NodeTestCase, async: false

  test "mutates env", %{env: env} do
    {:ok, env} = ConfigUpdate.execute(%{pin_number: 5, pin_value: 180}, [], env)
    assert_cs_env_mutation(SetServoAngle, env)
  end
end
