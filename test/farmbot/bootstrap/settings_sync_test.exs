defmodule Farmbot.Bootstrap.SettingsSyncTest do
  use ExUnit.Case, async: false
  alias Farmbot.Bootstrap.SettingsSync
  import Farmbot.System.ConfigStorage, only: [update_config_value: 4, get_config_value: 3]

  test "Applies new configs in the form of a map." do
    SettingsSync.apply_map(%{"firmware_output_log" => true}, %{"firmware_output_log" => false})
    refute get_config_value(:bool, "settings", "firmware_output_log")

    SettingsSync.apply_map(%{"firmware_hardware" => "arduino"}, %{"firmware_hardware" => "farmduino"})
    assert get_config_value(:string, "settings", "firmware_hardware") == "farmduino"

    SettingsSync.apply_map(%{"network_not_found_timer" => nil}, %{"network_not_found_timer" => 100})
    assert get_config_value(:float, "settings", "network_not_found_timer") == 100.0
  end

  test "doesn't crash on unknown key value pairs when applying a map" do
    Farmbot.System.Registry.subscribe(self())

    bad_map = %{
      "some_random_float" => 1.0,
      "some_random_string" => "hello world",
      "some_random_bool" => false
    }
    SettingsSync.apply_map(bad_map, %{})
    SettingsSync.apply_map(%{}, bad_map)
    refute_receive {Farmbot.System.Registry, {:config_storage, {"settings", "some_random_float", _}}}
    refute_receive {Farmbot.System.Registry, {:config_storage, {"settings", "some_random_string", _}}}
    refute_receive {Farmbot.System.Registry, {:config_storage, {"settings", "some_random_bool", _}}}
  end

  test "Updating configs externally will update in fbos" do
    Farmbot.System.Registry.subscribe(self())
    config_bin = %{
      "os_auto_update" => true
    } |> Poison.encode!
    update_config_value(:bool, "settings", "os_auto_update", false)
    assert_receive {Farmbot.System.Registry, {:config_storage, {"settings", "os_auto_update", false}}}

    %{status_code: 200} = Farmbot.HTTP.put!("/api/fbos_config", config_bin)
    Farmbot.Bootstrap.SettingsSync.run()
    assert_receive {Farmbot.System.Registry, {:config_storage, {"settings", "os_auto_update", true}}}, 2000
  end
end
