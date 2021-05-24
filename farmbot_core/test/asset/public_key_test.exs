defmodule FarmbotCore.Asset.PublicKeyTest do
  use ExUnit.Case
  alias FarmbotCore.Asset.PublicKey

  @expected_keys [:id, :name, :public_key]

  test "render/1" do
    result = PublicKey.render(%PublicKey{})
    mapper = fn key -> assert Map.has_key?(result, key) end
    Enum.map(@expected_keys, mapper)
  end
end
