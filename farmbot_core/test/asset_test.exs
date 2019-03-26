defmodule FarmbotCore.AssetTest do
  use ExUnit.Case, async: true
  alias FarmbotCore.Asset.{Repo, Regimen, RegimenInstance}
  alias FarmbotCore.Asset
  import Farmbot.TestSupport.AssetFixtures

  describe "regimen instances" do
    test "creates a regimen instance" do
      seq = sequence()
      reg = regimen(%{regimen_items: [%{time_offset: 100, sequence_id: seq.id}]})
      event = regimen_event(reg)
      assert %RegimenInstance{} = Asset.upsert_regimen_instance!(reg, event)
    end

    test "updates a persisten regimen" do
      seq = sequence()
      reg = regimen(%{name: "old", regimen_items: [%{time_offset: 100, sequence_id: seq.id}]})
      event = regimen_event(reg)
      pr = Asset.upsert_regimen_instance!(reg, event)
      assert pr.regimen.name == "old"
      reg = Regimen.changeset(reg, %{name: "new"}) |> Repo.update!()
      pr = Asset.upsert_regimen_instance!(reg, event)
      assert pr.regimen.name == "new"
    end
  end
end
