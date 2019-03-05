defmodule FarmbotCore.AssetTest do
  use ExUnit.Case, async: true
  alias FarmbotCore.Asset.{Repo, Regimen, PersistentRegimen}
  alias FarmbotCore.Asset
  import Farmbot.TestSupport.AssetFixtures

  describe "persistent regimens" do
    test "creates a persistent regimen" do
      seq = sequence()
      reg = regimen(%{regimen_items: [%{time_offset: 100, sequence_id: seq.id}]})
      event = regimen_event(reg)
      assert %PersistentRegimen{} = Asset.upsert_persistent_regimen!(reg, event)
    end

    test "updates a persisten regimen" do
      seq = sequence()
      reg = regimen(%{name: "old", regimen_items: [%{time_offset: 100, sequence_id: seq.id}]})
      event = regimen_event(reg)
      pr = Asset.upsert_persistent_regimen!(reg, event)
      assert pr.regimen.name == "old"
      reg = Regimen.changeset(reg, %{name: "new"}) |> Repo.update!()
      pr = Asset.upsert_persistent_regimen!(reg, event)
      assert pr.regimen.name == "new"
    end
  end
end
