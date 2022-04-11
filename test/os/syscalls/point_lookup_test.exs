defmodule FarmbotOS.SysCalls.PointLookupTest do
  use ExUnit.Case
  use Mimic
  import ExUnit.CaptureLog

  alias FarmbotOS.SysCalls.PointLookup
  alias FarmbotOS.Asset.Point
  alias FarmbotOS.Asset.Repo

  alias FarmbotOS.Asset.{
    Point,
    PointGroup,
    Repo,
    Tool
  }

  setup :verify_on_exit!

  test "catch malformed return values" do
    expect(FarmbotOS.Asset, :get_point, 1, fn _ ->
      :example_error_for_unit_tests
    end)

    t = fn -> PointLookup.point("GenericPointer", 1) end

    expected_log =
      "Point error: Please notify support :example_error_for_unit_tests"

    assert(capture_log(t)) =~ expected_log
  end

  test "failure cases" do
    err1 = PointLookup.point("GenericPointer", 24)
    assert {:error, "GenericPointer 24 not found"} == err1

    err2 = PointLookup.get_toolslot_for_tool(24)
    assert {:error, "Could not find point for tool by id: 24"} == err2

    err3 = PointLookup.get_point_group(24)
    assert {:error, "Could not find PointGroup.24"} == err3
  end

  test "PointLookup.point/2" do
    Helpers.delete_all_points()

    expected = %{
      name: "test suite III",
      x: 1.2,
      y: 3.4,
      z: 5.6,
      resource_id: 555,
      resource_type: "GenericPointer"
    }

    p = point(expected)

    actual =
      PointLookup.point("GenericPointer", p.id)
      |> Map.take([:name, :x, :y, :z, :resource_id, :resource_type])

    assert expected == actual
  end

  test "PointLookup.get_toolslot_for_tool/1 (gantry mounted tool)" do
    Helpers.delete_all_points()
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

    result =
      PointLookup.get_toolslot_for_tool(t.id)
      |> Map.take([:name, :x, :y, :z, :gantry_mounted])

    assert important_part == result
  end

  test "PointLookup.get_toolslot_for_tool/1" do
    Helpers.delete_all_points()
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

    actual =
      PointLookup.get_toolslot_for_tool(t.id)
      |> Map.take([:name, :x, :y, :z, :gantry_mounted])

    assert important_part == actual
  end

  test "PointLookup.get_point_group/1 - int" do
    Repo.delete_all(PointGroup)
    Helpers.delete_all_points()

    pg = point_group(%{point_ids: [1, 2, 3]})

    assert pg == PointLookup.get_point_group(pg.id)
  end

  @tag :capture_log
  test "PointLookup.get_point_group/1 - string" do
    Repo.delete_all(PointGroup)
    Helpers.delete_all_points()

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
