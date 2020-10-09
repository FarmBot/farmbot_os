defmodule FarmbotCore.Asset.FarmEvent.BodyNodeTest do
  use ExUnit.Case, async: true
  alias FarmbotCore.Asset.FarmEvent.BodyNode

  test "changeset" do
    bn = %BodyNode{kind: "parameter_application", args: %{}}
    result = BodyNode.render(bn)
    assert bn.args == result[:args]
    assert bn.kind == result[:kind]
  end
end
