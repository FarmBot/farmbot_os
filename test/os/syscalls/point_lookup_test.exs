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

  test "PointLookup.point/2 (plant with age)" do
    Helpers.delete_all_points()

    expected = %{
      name: "plant",
      x: 1.2,
      y: 3.4,
      z: 5.6,
      age: 1,
      resource_id: 555,
      resource_type: "Plant"
    }

    p =
      point(
        expected
        |> Map.put(:pointer_type, "Plant")
        |> Map.put(
          :planted_at,
          DateTime.utc_now() |> DateTime.add(-7200, :second)
        )
      )

    actual =
      PointLookup.point("Plant", p.id)
      |> Map.take([:name, :x, :y, :z, :age, :resource_id, :resource_type])

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
      mount_stage: 0,
      mount_offset_x: 0.0,
      mount_offset_y: 0.0,
      mount_offset_z: 0.0,
      x: 4.4,
      y: 4.4,
      z: 4.4
    })

    important_part = %{
      name: "Tool Slot",
      x: 9.99,
      y: 4.4,
      z: 4.4,
      gantry_mounted: true,
      mount_stage: 0,
      mount_offset_x: 0.0,
      mount_offset_y: 0.0,
      mount_offset_z: 0.0
    }

    result =
      PointLookup.get_toolslot_for_tool(t.id)
      |> Map.take([
        :name,
        :x,
        :y,
        :z,
        :gantry_mounted,
        :mount_stage,
        :mount_offset_x,
        :mount_offset_y,
        :mount_offset_z
      ])

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
      gantry_mounted: false,
      mount_stage: 0,
      mount_offset_x: 0.0,
      mount_offset_y: 0.0,
      mount_offset_z: 0.0
    }

    other_stuff = %{
      pointer_type: "ToolSlot",
      tool_id: t.id
    }

    point(Map.merge(important_part, other_stuff))

    actual =
      PointLookup.get_toolslot_for_tool(t.id)
      |> Map.take([
        :name,
        :x,
        :y,
        :z,
        :gantry_mounted,
        :mount_stage,
        :mount_offset_x,
        :mount_offset_y,
        :mount_offset_z
      ])

    assert important_part == actual
  end

  test "PointLookup.get_toolslot_for_tool/1 adjusts coordinates by mount stage" do
    Helpers.delete_all_points()
    Repo.delete_all(Tool)

    expect(FarmbotOS.SysCalls.Movement, :get_current_x, 3, fn -> 10.0 end)
    expect(FarmbotOS.SysCalls.Movement, :get_current_y, 2, fn -> 20.0 end)
    expect(FarmbotOS.SysCalls.Movement, :get_current_z, 1, fn -> 30.0 end)

    x_stage = mounted_toolslot(1, 1)
    y_stage = mounted_toolslot(2, 2)
    z_stage = mounted_toolslot(3, 3)

    assert %{x: 10.1, y: 2.0, z: 3.0} =
             PointLookup.get_toolslot_for_tool(x_stage.id)

    assert %{x: 10.1, y: 20.2, z: 3.0} =
             PointLookup.get_toolslot_for_tool(y_stage.id)

    assert %{x: 10.1, y: 20.2, z: 30.3} =
             PointLookup.get_toolslot_for_tool(z_stage.id)
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

  defp mounted_toolslot(id, mount_stage) do
    mounted_tool = tool(%{id: id, name: "mounted tool #{id}"})

    point(%{
      id: id,
      pointer_type: "ToolSlot",
      tool_id: mounted_tool.id,
      mount_stage: mount_stage,
      mount_offset_x: 0.1,
      mount_offset_y: 0.2,
      mount_offset_z: 0.3,
      x: 1.0,
      y: 2.0,
      z: 3.0
    })

    mounted_tool
  end
end
