defmodule FarmbotOS.Asset.SyncTest do
  use ExUnit.Case

  alias FarmbotOS.Asset.Sync

  @expected_keys [
    :curves,
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

  test "casts and renders curve sync items" do
    params = %{
      "curves" => [[123, "2026-10-09T00:00:00.000000Z"]]
    }

    changeset = Sync.changeset(%Sync{}, params)
    assert changeset.valid?
    sync = Ecto.Changeset.apply_changes(changeset)
    assert [%{id: 123}] = Sync.render(sync).curves

    assert {FarmbotOS.Asset.Curve, sync.curves} ==
             FarmbotOS.EagerLoader.get_sync_items(FarmbotOS.Asset.Curve, sync)
  end

  test "render/1" do
    result = Sync.render(%Sync{})
    mapper = fn key -> assert Map.has_key?(result, key) end
    Enum.map(@expected_keys, mapper)
  end
end
