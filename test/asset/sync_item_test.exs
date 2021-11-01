defmodule FarmbotOS.Asset.Sync.ItemTest do
  use ExUnit.Case

  alias FarmbotOS.Asset.Sync.Item

  @expected_keys [:id, :updated_at]

  test "render/1" do
    result = Item.render(%Item{})
    mapper = fn key -> assert Map.has_key?(result, key) end
    Enum.map(@expected_keys, mapper)
  end
end
