defmodule FarmbotOS.Asset.PrivateTest do
  use ExUnit.Case

  alias FarmbotOS.Asset.{
    FbosConfig,
    FirmwareConfig,
    Point,
    Private,
    Repo
  }

  @assets %{
    Point => %Point{gantry_mounted: false, pullout_direction: 0},
    FbosConfig => %FbosConfig{},
    FirmwareConfig => %FirmwareConfig{}
  }

  def destroy_assets() do
    Map.keys(@assets) |> Enum.map(&Repo.delete_all/1)
  end

  def create_assets() do
    %{
      Point => Repo.insert!(@assets[Point]),
      FbosConfig => Repo.insert!(@assets[FbosConfig]),
      FirmwareConfig => Repo.insert!(@assets[FirmwareConfig])
    }
  end

  def reset_assets() do
    destroy_assets()
    # create_assets()
  end

  test "list_local" do
    destroy_assets()
    old_results = Private.list_local(Point)
    assert Enum.count(old_results) == 0

    %{Point => created_point} = create_assets()
    new_results = Private.list_local(Point)
    assert Enum.count(new_results) == 1
    local_point = Enum.at(new_results, 0)
    assert local_point == created_point
    reset_assets()
  end

  test "mark_dirty! / list_dirty" do
    Map.keys(@assets)
    |> Enum.map(fn mod ->
      # INITIAL STATE: Should be empty
      destroy_assets()
      old_count = Enum.count(Private.list_dirty(mod))
      assert old_count == 0

      # MARK DIRTY: Should list exactly 1 dirty resource
      asset = Map.fetch!(create_assets(), mod)
      Private.mark_dirty!(asset)
      new_count = Enum.count(Private.list_dirty(mod))
      assert new_count == 1

      # MARK CLEAN: Should list 0
      Private.mark_clean!(asset)
      newer_count = Enum.count(Private.list_dirty(mod))
      assert newer_count == 0
    end)

    reset_assets()
  end

  test "Private.any_stale?() returns false when there are not stale records" do
    Repo.delete_all(FarmbotOS.Asset.Private.LocalMeta)
    refute Private.any_stale?()
  end
end
