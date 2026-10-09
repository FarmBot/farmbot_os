defmodule Farmbot.TestSupport.AssetFixturesTest do
  use ExUnit.Case

  alias Farmbot.TestSupport.AssetFixtures

  test "regimen defaults use distinct negative IDs" do
    first = AssetFixtures.regimen()
    second = AssetFixtures.regimen()

    assert first.id < 0
    assert second.id < 0
    refute first.id == second.id
  end

  test "regimen preserves an explicit ID" do
    id = System.unique_integer([:positive, :monotonic])
    regimen = AssetFixtures.regimen(%{id: id})

    assert regimen.id == id
  end
end
