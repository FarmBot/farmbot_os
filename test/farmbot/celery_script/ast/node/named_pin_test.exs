defmodule Farmbot.CeleryScript.AST.Node.NamedPinTest do
  use FarmbotTestSupport.AST.NodeTestCase, async: false
  alias Farmbot.CeleryScript.AST.Node.NamedPin

  test "mutates env", %{env: env} do
    {:ok, _, env} = NamedPin.execute(%{pin_type: :digital, pin_id: 1000}, [], env)
    assert_cs_env_mutation(NamedPin, env)
  end
end
