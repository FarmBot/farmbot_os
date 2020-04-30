defmodule FarmbotOS.SysCalls.ResourceUpdateTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.SysCalls.ResourceUpdate
  alias FarmbotOS.SysCalls.PointLookup
  alias FarmbotCore.Asset.{Point, Repo}

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
    assert "X is 1.2" == FarmbotCore.Asset.device().name
  end

  test "update_resource/3 - Point" do
    Repo.delete_all(Point)

    %Point{id: 555, pointer_type: "Plant"}
    |> Point.changeset()
    |> Repo.insert!()

    params = %{name: "Updated to {{ x }}"}
    assert :ok == ResourceUpdate.update_resource("Plant", 555, params)
    next_plant = PointLookup.point("Plant", 555)
    assert "Updated to " == next_plant.name

    bad_result1 = ResourceUpdate.update_resource("Plant", 0, params)
    error = "Plant.0 is not currently synced, so it could not be updated"
    assert {:error, error} == bad_result1
  end

  test "update_resource/3 - unknown" do
    {:error, error} = ResourceUpdate.update_resource("Foo", 0, nil)
    assert error == "Unknown resource: Foo.0\n"
  end
end
