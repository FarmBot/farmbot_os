defmodule FarmbotOS.SysCalls.ResourceUpdateTest do
  use ExUnit.Case

  alias FarmbotOS.SysCalls.ResourceUpdate
  alias FarmbotOS.SysCalls.PointLookup
  alias FarmbotCore.Asset.{
    Point,
    Repo,
  }

  test "resource_update/3 - Device" do
    params = %{name: "X is {{ x }}"}
    assert :ok == ResourceUpdate.resource_update("Device", 0, params)
    assert "X is -1" == FarmbotCore.Asset.device().name
  end

  test "resource_update/3 - Point" do
    Repo.delete_all(Point)

    %Point{id: 555, pointer_type: "Plant"}
    |> Point.changeset()
    |> Repo.insert!()

    params = %{name: "Updated to {{ x }}"}
    assert :ok == ResourceUpdate.resource_update("Plant", 555, params)
    next_plant = PointLookup.point("Plant", 555)
    assert "Updated to -1" == next_plant.name

    bad_result1 = ResourceUpdate.resource_update("Plant", 0, params)
    error = "Plant.0 is not currently synced, so it could not be updated"
    assert {:error, error} == bad_result1
  end

  test "resource_update/3 - unknown" do
    params = %{name: "never called"}
    {:error, error } = ResourceUpdate.resource_update("Foo", 0, nil)
    assert error == "Unknown resource: Foo.0\n"
  end
end
