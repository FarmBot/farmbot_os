defmodule Farmbot.Bootstrap.SettingsSyncTest do
  use ExUnit.Case, async: false
  alias Farmbot.Bootstrap.SettingsSync
  import Farmbot.System.ConfigStorage, only: [update_config_value: 4, get_config_value: 3]

  test "Applies new configs" do
    SettingsSync.apply_map(%{"firmware_output_log" => true}, %{"firmware_output_log" => false})
    refute get_config_value(:bool, "settings", "firmware_output_log")

    SettingsSync.apply_map(%{"firmware_hardware" => "arduino"}, %{"firmware_hardware" => "farmduino"})
    assert get_config_value(:string, "settings", "firmware_hardware") == "farmduino"

    SettingsSync.apply_map(%{"network_not_found_timer" => nil}, %{"network_not_found_timer" => 100})
    assert get_config_value(:float, "settings", "network_not_found_timer") == 100.0
  end


end
