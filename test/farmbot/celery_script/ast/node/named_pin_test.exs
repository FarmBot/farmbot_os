defmodule Farmbot.CeleryScript.AST.Node.NamedPinTest do
  alias Farmbot.CeleryScript.AST.Node.NamedPin

  use FarmbotTestSupport.AST.NodeTestCase, async: false

  test "mutates env", %{env: env} do
    {:ok, env} = NamedPin.execute(%{}, [], env)
    assert_cs_env_mutation(NamedPin, env)
  end
end
