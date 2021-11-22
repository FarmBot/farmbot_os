defmodule FarmbotOS.SysCalls.ResourceUpdateTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.SysCalls.ResourceUpdate
  alias FarmbotOS.SysCalls.PointLookup
  alias FarmbotOS.Asset.{Point, Repo}
  alias FarmbotOS.Asset

  setup :verify_on_exit!

  def fake_coords! do
    expect(FarmbotOS.SysCalls, :get_cached_position, fn ->
      [x: 1.2, y: 2.3, z: 3.4]
    end)
  end

  test "update_resource/3 - Device" do
    fake_coords!()
    params = %{name: "X is {{ x }}"}
    assert :ok == ResourceUpdate.update_resource("Device", 0, params)
    assert "X is 1.2" == FarmbotOS.Asset.device().name
  end

  test "update_resource/3 - Point" do
    Helpers.delete_all_points()

    %Point{id: 555, pointer_type: "Plant"}
    |> Point.changeset()
    |> Repo.insert!()

    params = %{name: "Updated to {{ x }}"}
    assert :ok == ResourceUpdate.update_resource("Plant", 555, params)
    next_plant = PointLookup.point("Plant", 555)
    assert String.contains?(next_plant.name, "Updated to ")

    bad_result1 = ResourceUpdate.update_resource("Plant", 0, params)
    error = "Plant.0 is not currently synced. Please re-sync."
    assert {:error, error} == bad_result1
  end

  test "update_resource/3 - unknown" do
    {:error, error} = ResourceUpdate.update_resource("Foo", 0, nil)
    assert error == "Unknown resource: Foo.0\n"
  end

  test "point_update_resource/3" do
    expect(Asset, :get_point, 1, fn opts ->
      assert [id: 123] == opts
      {:error, "this is a test"}
    end)

    expected =
      {:error, "Failed update (Foo.123): Ensure the data is properly formatted"}

    actual = ResourceUpdate.point_update_resource("Foo", 123, nil)
    assert expected == actual
  end
end
