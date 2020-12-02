defmodule FarmbotCore.Asset.PinBindingTest do
  use ExUnit.Case, async: true
  alias FarmbotCore.Asset.PinBinding

  @expected_keys [:id, :pin_num, :sequence_id, :special_action]

  test "render/1" do
    result = PinBinding.render(%PinBinding{})
    mapper = fn key -> assert Map.has_key?(result, key) end
    Enum.map(@expected_keys, mapper)
  end
end
