defmodule FarmbotOS.Asset.ToolTest do
  use ExUnit.Case
  alias FarmbotOS.Asset.Tool

  @expected_keys [:id, :name]

  test "render/1" do
    result = Tool.render(%Tool{})
    mapper = fn key -> assert Map.has_key?(result, key) end
    Enum.map(@expected_keys, mapper)
  end
end
