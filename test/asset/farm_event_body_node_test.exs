defmodule FarmbotOS.Asset.FarmEvent.BodyNodeTest do
  use ExUnit.Case
  alias FarmbotOS.Asset.FarmEvent.BodyNode

  @expected_keys [:kind, :args]

  test "render/1" do
    result = BodyNode.render(%BodyNode{})
    mapper = fn key -> assert Map.has_key?(result, key) end
    Enum.map(@expected_keys, mapper)
  end

  test "changeset" do
    bn = %BodyNode{kind: "parameter_application", args: %{}}
    result = BodyNode.render(bn)
    assert bn.args == result[:args]
    assert bn.kind == result[:kind]
  end
end
