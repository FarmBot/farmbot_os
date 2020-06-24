defmodule FarmbotCore.Asset.PrivateTest do
  use ExUnit.Case, async: true

  alias FarmbotCore.Asset.{
    FbosConfig,
    FirmwareConfig,
    Point,
    Private,
    Repo
  }

  @assets [Point, FbosConfig, FirmwareConfig]

  def destroy_assets() do
    Enum.map(@assets, &Repo.delete_all/1)
  end

  def create_assets() do
    %{
      point: Repo.insert!(%Point{gantry_mounted: false, pullout_direction: 0}),
      fbos_config: Repo.insert!(%FbosConfig{}),
      firmware_config: Repo.insert!(%FirmwareConfig{})
    }
  end

  test "list_local" do
    destroy_assets()
    old_results = Private.list_local(Point)
    assert Enum.count(old_results) == 0

    %{point: created_point} = create_assets()
    new_results = Private.list_local(Point)
    assert Enum.count(new_results) == 1
    local_point = Enum.at(new_results, 0)
    assert local_point == created_point
  end

  test "mark_stale!" do
    destroy_assets()
    %{firmware_config: firmware_config} = create_assets()
    refute Private.any_stale?()
    Private.mark_stale!(firmware_config)
    assert Private.any_stale?()
  end
end
