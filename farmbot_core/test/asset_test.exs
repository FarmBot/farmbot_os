defmodule FarmbotCore.AssetTest do
  use ExUnit.Case, async: true
  alias FarmbotCore.Asset.RegimenInstance
  alias FarmbotCore.Asset
  import Farmbot.TestSupport.AssetFixtures

  describe "regimen instances" do
    test "creates a regimen instance" do
      seq = sequence()

      reg =
        regimen(%{regimen_items: [%{time_offset: 100, sequence_id: seq.id}]})

      event = regimen_event(reg)
      assert %RegimenInstance{} = Asset.new_regimen_instance!(event)
    end
  end

  test "Asset.device/1" do
    assert nil == Asset.device(:ota_hour)
    assert %FarmbotCore.Asset.Device{} = Asset.update_device!(%{ota_hour: 17})
    assert 17 == Asset.device(:ota_hour)
  end
end
