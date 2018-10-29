defmodule Farmbot.Core.CeleryScriptTest do
  use ExUnit.Case
  import Farmbot.TestSupport.AssetFixtures
  alias Farmbot.Core.CeleryScript
  alias Farmbot.TestSupport.CeleryScript.TestIOLayer

  test "rpc_request" do
    TestIOLayer.subscribe()
    debug_ast = TestIOLayer.debug_ast()
    CeleryScript.rpc_request(debug_ast, &TestIOLayer.debug_fun/1)
    assert_receive ^debug_ast
  end

  test "sequence" do
    TestIOLayer.subscribe()
    debug_ast = TestIOLayer.debug_ast()
    seq = sequence(%{args: %{}, body: [debug_ast]})
    CeleryScript.sequence(seq, &TestIOLayer.debug_fun/1)
    assert_receive ^debug_ast
  end
end
