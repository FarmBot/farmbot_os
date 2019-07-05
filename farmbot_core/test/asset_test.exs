defmodule FarmbotCore.AssetTest do
  use ExUnit.Case, async: true
  alias FarmbotCore.Asset.RegimenInstance
  alias FarmbotCore.Asset
  import Farmbot.TestSupport.AssetFixtures

  describe "regimen instances" do
    test "creates a regimen instance" do
      seq = sequence()
      reg = regimen(%{regimen_items: [%{time_offset: 100, sequence_id: seq.id}]})
      event = regimen_event(reg)
      assert %RegimenInstance{} = Asset.new_regimen_instance!(event)
    end
  end
end
