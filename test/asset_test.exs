defmodule FarmbotOS.AssetTest do
  use ExUnit.Case

  alias FarmbotOS.Asset.RegimenInstance

  alias FarmbotOS.Asset
  import Farmbot.TestSupport.AssetFixtures

  describe "regimen instances" do
    test "creates a regimen instance" do
      Asset.update_device!(%{timezone: "America/Chicago"})
      seq = sequence()

      reg =
        regimen(%{regimen_items: [%{time_offset: 100, sequence_id: seq.id}]})

      event = regimen_event(reg)
      assert %RegimenInstance{} = Asset.new_regimen_instance!(event)
    end
  end

  test "Asset.device/1" do
    assert nil == Asset.device(:ota_hour)
    assert %FarmbotOS.Asset.Device{} = Asset.update_device!(%{ota_hour: 17})
    assert 17 == Asset.device(:ota_hour)
  end

  describe "firmware config" do
    test "retrieves a single field" do
      FarmbotOS.Asset.Repo.delete_all(FarmbotOS.Asset.FirmwareConfig)
      conf = Asset.firmware_config()
      refute 1.23 == Asset.firmware_config(:movement_steps_acc_dec_x)
      Asset.update_firmware_config!(conf, %{movement_steps_acc_dec_x: 1.23})
      assert 1.23 == Asset.firmware_config(:movement_steps_acc_dec_x)
    end
  end
end
