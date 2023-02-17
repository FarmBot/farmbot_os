defmodule FarmbotOS.SysCalls.FactoryResetTest do
  use ExUnit.Case
  use Mimic

  require Helpers

  alias FarmbotOS.SysCalls.FactoryReset
  alias FarmbotOS.{Asset, BotState, APIFetcher}

  setup :verify_on_exit!

  test "factory reset - FarmBot OS" do
    expect(FarmbotOS.System, :factory_reset, 1, fn reason, flag ->
      assert reason == "reason"
      assert flag
      :ok
    end)

    assert :ok == FactoryReset.factory_reset("farmbot_os", "reason")
  end

  test "factory reset - Arduino" do
    expect(APIFetcher, :delete!, 1, fn _, "/api/firmware_config" ->
      :unit_test
    end)

    expect(APIFetcher, :get!, 1, fn _, "/api/firmware_config" ->
      :unit_test
    end)

    expect(BotState, :set_sync_status, 1, fn "maintenance" ->
      :unit_test
    end)

    expect(FarmbotOS.System, :reboot, 1, fn "Arduino factory reset" ->
      :unit_test
    end)

    Helpers.expect_log("Arduino Firmware going down for factory reset!")
    expect(Asset, :firmware_config, 1, fn :id -> 123 end)
    expect(Asset, :delete_firmware_config!, 1, fn 123 -> :ok end)
    assert :ok == FactoryReset.factory_reset("arduino_firmware")
  end
end
