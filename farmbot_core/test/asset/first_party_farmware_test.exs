defmodule FarmbotCore.Asset.FirstPartyFarmwareTest do
  use ExUnit.Case
  alias FarmbotCore.Asset.FirstPartyFarmware

  @expected_keys [:id, :url]

  test "render/1" do
    result = FirstPartyFarmware.render(%FirstPartyFarmware{})
    mapper = fn key -> assert Map.has_key?(result, key) end
    Enum.map(@expected_keys, mapper)
  end
end
