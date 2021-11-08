defmodule FarmbotOS.Asset.SyncTest do
  use ExUnit.Case

  alias FarmbotOS.Asset.Sync

  @expected_keys [
    :devices,
    :farm_events,
    :farmware_envs,
    :farmware_installations,
    :fbos_configs,
    :firmware_configs,
    :first_party_farmwares,
    :now,
    :peripherals,
    :pin_bindings,
    :point_groups,
    :points,
    :public_keys,
    :regimens,
    :sensor_readings,
    :sensors,
    :sequences,
    :tools
  ]

  test "render/1" do
    result = Sync.render(%Sync{})
    mapper = fn key -> assert Map.has_key?(result, key) end
    Enum.map(@expected_keys, mapper)
  end
end
