defmodule FarmbotOS.SysCalls.PointLookupTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotOS.SysCalls.PointLookup
  alias FarmbotOS.SysCalls.ResourceUpdate
  alias FarmbotCore.Asset.Point
  alias FarmbotCore.Asset.Repo

  alias FarmbotCore.Asset.{
    Point,
    Repo,
    Tool
  }

  test "failure cases" do
    err1 = PointLookup.point("GenericPointer", 24)
    assert {:error, "GenericPointer not found"} == err1

    err2 = PointLookup.get_toolslot_for_tool(24)
    assert {:error, "Could not find point for tool by id: 24"} == err2

    err3 = PointLookup.get_point_group(24)
    assert {:error, "Could not find PointGroup.24"} == err3
  end

  test "PointLookup.point/2" do
    Repo.delete_all(Point)

    expected = %{
      name: "test suite III",
      x: 1.2,
      y: 3.4,
      z: 5.6
    }

    p = point(expected)

    assert expected == PointLookup.point("GenericPointer", p.id)
  end

  test "PointLookup.get_toolslot_for_tool/1" do
    Repo.delete_all(Point)
    t = tool(%{name: "moisture probe"})

    important_part = %{
      name: "Tool Slot",
      x: 1.9,
      y: 2.9,
      z: 3.9
    }

    other_stuff = %{
      pointer_type: "ToolSlot",
      tool_id: t.id
    }

    point(Map.merge(important_part, other_stuff))
    assert important_part == PointLookup.get_toolslot_for_tool(t.id)
  end

  defp point(extra_stuff) do
    base = %Point{id: 555, pointer_type: "GenericPointer"}

    Map.merge(base, extra_stuff)
    |> Point.changeset()
    |> Repo.insert!()
  end

  defp tool(extra_stuff) do
    base = %Tool{id: 555}

    Map.merge(base, extra_stuff)
    |> Tool.changeset()
    |> Repo.insert!()
  end
end
