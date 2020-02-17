defmodule FarmbotOS.SysCalls.PointLookupTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotOS.SysCalls.PointLookup
  alias FarmbotOS.SysCalls.ResourceUpdate
  alias FarmbotCore.Asset.Point
  alias FarmbotCore.Asset.Repo

  test "failure cases" do
    err1 = PointLookup.point("GenericPointer", 24)
    assert {:error, "GenericPointer not found"} == err1

    err2 = PointLookup.get_toolslot_for_tool(24)
    assert {:error, "Could not find point for tool by id: 24"} == err2

    err3 = PointLookup.get_point_group(24)
    assert {:error, "Could not find PointGroup.24"} == err3
  end

  test "PointLookup.point/2" do
    expected = %{
      name: "test suite III",
      x: 1.2,
      y: 3.4,
      z: 5.6
    }
   point = %Point{id: 555, pointer_type: "GenericPointer"}

    Map.merge(point, expected)
      |> Point.changeset()
      |> Repo.insert!()

    assert expected == PointLookup.point("GenericPointer", point.id)
  end
end
