defmodule FarmbotCore.Asset.Regimen.ItemTest do
  use ExUnit.Case, async: true
  alias FarmbotCore.Asset.Regimen.Item

  @expected_keys [:time_offset, :sequence_id]

  test "render/1" do
    result = Item.render(%Item{})
    mapper = fn key -> assert Map.has_key?(result, key) end
    Enum.map(@expected_keys, mapper)
  end
end
