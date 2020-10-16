defmodule FarmbotCore.Asset.Regimen.BodyNodeTest do
  use ExUnit.Case, async: true
  alias FarmbotCore.Asset.Regimen.BodyNode

  @expected_keys [:kind, :args]

  test "render/1" do
    result = BodyNode.render(%BodyNode{})
    mapper = fn key -> assert Map.has_key?(result, key) end
    Enum.map(@expected_keys, mapper)
  end
end
