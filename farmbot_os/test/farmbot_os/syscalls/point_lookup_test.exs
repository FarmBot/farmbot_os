defmodule FarmbotOS.SysCalls.PointLookupTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.SysCalls.PointLookup
  alias FarmbotCore.Asset.Point
  alias FarmbotCore.Asset.Repo

  alias FarmbotCore.Asset.{
    Point,
    PointGroup,
    Repo,
    Tool
  }

  setup :verify_on_exit!

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

  test "PointLookup.get_toolslot_for_tool/1 (gantry mounted tool)" do
    Repo.delete_all(Point)
    Repo.delete_all(Tool)
    expect(FarmbotOS.SysCalls.Movement, :get_current_x, 1, fn -> 9.99 end)

    t = tool(%{name: "moisture probe"})

    point(%{
      pointer_type: "ToolSlot",
      name: "Tool Slot",
      tool_id: t.id,
      gantry_mounted: true,
      x: 4.4,
      y: 4.4,
      z: 4.4
    })

    important_part = %{
      name: "Tool Slot",
      x: 9.99,
      y: 4.4,
      z: 4.4,
      gantry_mounted: true
    }

    assert important_part == PointLookup.get_toolslot_for_tool(t.id)
  end

  test "PointLookup.get_toolslot_for_tool/1" do
    Repo.delete_all(Point)
    Repo.delete_all(Tool)

    t = tool(%{name: "moisture probe"})

    important_part = %{
      name: "Tool Slot",
      x: 1.9,
      y: 2.9,
      z: 3.9,
      gantry_mounted: false
    }

    other_stuff = %{
      pointer_type: "ToolSlot",
      tool_id: t.id
    }

    point(Map.merge(important_part, other_stuff))
    assert important_part == PointLookup.get_toolslot_for_tool(t.id)
  end

  test "PointLookup.get_point_group/1 - int" do
    Repo.delete_all(PointGroup)
    Repo.delete_all(Point)

    pg = point_group(%{point_ids: [1, 2, 3]})

    assert pg == PointLookup.get_point_group(pg.id)
  end

  test "PointLookup.get_point_group/1 - string" do
    Repo.delete_all(PointGroup)
    Repo.delete_all(Point)

    point(%{pointer_type: "ToolSlot", id: 601})
    point(%{pointer_type: "Plant", id: 602})
    point(%{pointer_type: "GenericPointer", id: 603})
    %{point_ids: list} = PointLookup.get_point_group("Plant")
    assert list == [602]
  end

  defp point_group(extra_stuff) do
    base = %PointGroup{id: 555}

    Map.merge(base, extra_stuff)
    |> PointGroup.changeset()
    |> Repo.insert!()
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
