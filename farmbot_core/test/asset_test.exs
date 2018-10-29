defmodule Farmbot.AssetTest do
  use ExUnit.Case
  alias Farmbot.Asset.{Repo, Regimen, PersistentRegimen}
  alias Farmbot.Asset
  import Farmbot.TestSupport.AssetFixtures

  describe "persistent regimens" do
    test "creates a persistent regimen" do
      seq = sequence()
      reg = regimen(%{regimen_items: [%{time_offset: 100, sequence_id: seq.id}]})
      event = regimen_event(reg)
      assert {:ok, %PersistentRegimen{}} = Asset.upsert_persistent_regimen(reg, event)
    end

    test "updates a persisten regimen" do
      seq = sequence()
      reg = regimen(%{name: "old", regimen_items: [%{time_offset: 100, sequence_id: seq.id}]})
      event = regimen_event(reg)
      {:ok, pr} = Asset.upsert_persistent_regimen(reg, event)
      assert pr.regimen.name == "old"
      reg = Regimen.changeset(reg, %{name: "new"}) |> Repo.update!()
      {:ok, pr} = Asset.upsert_persistent_regimen(reg, event)
      assert pr.regimen.name == "new"
    end
  end
end
