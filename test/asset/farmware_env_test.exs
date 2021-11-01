defmodule FarmbotOS.Asset.FarmwareEnvTest do
  use ExUnit.Case
  alias FarmbotOS.Asset.FarmwareEnv

  @expected_keys [:id, :key, :value]

  test "render/1" do
    result = FarmwareEnv.render(%FarmwareEnv{})
    mapper = fn key -> assert Map.has_key?(result, key) end
    Enum.map(@expected_keys, mapper)
  end
end
