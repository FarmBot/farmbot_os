defmodule FarmbotOS.AssetTest do
  use ExUnit.Case

  alias FarmbotOS.Asset.RegimenInstance

  alias FarmbotOS.Asset
  import Farmbot.TestSupport.AssetFixtures

  describe "get_tool_slot/1" do
    test "returns only the active tool slot for the requested tool" do
      tool_id = -System.unique_integer([:positive])
      other_tool_id = tool_id - 1

      points = [
        %Asset.Point{
          tool_id: tool_id,
          pointer_type: "ToolSlot",
          discarded_at: ~U[2023-01-01 00:00:00.000000Z]
        },
        %Asset.Point{tool_id: tool_id, pointer_type: "GenericPointer"},
        %Asset.Point{tool_id: other_tool_id, pointer_type: "ToolSlot"},
        %Asset.Point{tool_id: tool_id, pointer_type: "ToolSlot"}
      ]

      inserted = Enum.map(points, &Asset.Repo.insert!/1)
      on_exit(fn -> Enum.each(inserted, &Asset.Repo.delete!/1) end)
      active = List.last(inserted)

      assert Asset.get_tool_slot(tool_id).local_id == active.local_id
    end

    test "returns nil when the tool has no active slot" do
      tool_id = -System.unique_integer([:positive])

      discarded =
        Asset.Repo.insert!(%Asset.Point{
          tool_id: tool_id,
          pointer_type: "ToolSlot",
          discarded_at: ~U[2023-01-01 00:00:00.000000Z]
        })

      on_exit(fn -> Asset.Repo.delete!(discarded) end)

      assert Asset.get_tool_slot(tool_id) == nil
    end
  end

  describe "regimen instances" do
    test "creates a regimen instance" do
      Asset.update_device!(%{timezone: "America/Chicago"})
      seq = sequence()

      reg =
        regimen(%{regimen_items: [%{time_offset: 100, sequence_id: seq.id}]})

      event = regimen_event(reg)
      assert %RegimenInstance{} = Asset.new_regimen_instance!(event)
    end
  end

  test "Asset.device/1" do
    assert nil == Asset.device(:ota_hour)
    assert %FarmbotOS.Asset.Device{} = Asset.update_device!(%{ota_hour: 17})
    assert 17 == Asset.device(:ota_hour)
  end

  describe "firmware config" do
    test "retrieves a single field" do
      FarmbotOS.Asset.Repo.delete_all(FarmbotOS.Asset.FirmwareConfig)
      conf = Asset.firmware_config()
      refute 1.23 == Asset.firmware_config(:movement_steps_acc_dec_x)
      Asset.update_firmware_config!(conf, %{movement_steps_acc_dec_x: 1.23})
      assert 1.23 == Asset.firmware_config(:movement_steps_acc_dec_x)
    end
  end

  describe "sort_points()" do
    test "xy_ascending" do
      points = [
        %Asset.Point{id: 1, x: 1, y: 1},
        %Asset.Point{id: 2, x: 2, y: 2},
        %Asset.Point{id: 3, x: 0, y: 10},
        %Asset.Point{id: 4, x: 10, y: 0},
        %Asset.Point{id: 5, x: 10, y: 10}
      ]

      assert Asset.sort_points(points, "xy_ascending")
             |> Enum.map(fn p -> p.id end) == [3, 1, 2, 4, 5]
    end

    test "yx_ascending" do
      points = [
        %Asset.Point{id: 1, x: 1, y: 1},
        %Asset.Point{id: 2, x: 2, y: 2},
        %Asset.Point{id: 3, x: 0, y: 10},
        %Asset.Point{id: 4, x: 10, y: 0},
        %Asset.Point{id: 5, x: 10, y: 10}
      ]

      assert Asset.sort_points(points, "yx_ascending")
             |> Enum.map(fn p -> p.id end) == [4, 1, 2, 3, 5]
    end

    test "xy_descending" do
      points = [
        %Asset.Point{id: 1, x: 1, y: 1},
        %Asset.Point{id: 2, x: 2, y: 2},
        %Asset.Point{id: 3, x: 0, y: 10},
        %Asset.Point{id: 4, x: 10, y: 0},
        %Asset.Point{id: 5, x: 10, y: 10}
      ]

      assert Asset.sort_points(points, "xy_descending")
             |> Enum.map(fn p -> p.id end) == [5, 4, 2, 1, 3]
    end

    test "yx_descending" do
      points = [
        %Asset.Point{id: 1, x: 1, y: 1},
        %Asset.Point{id: 2, x: 2, y: 2},
        %Asset.Point{id: 3, x: 0, y: 10},
        %Asset.Point{id: 4, x: 10, y: 0},
        %Asset.Point{id: 5, x: 10, y: 10}
      ]

      assert Asset.sort_points(points, "yx_descending")
             |> Enum.map(fn p -> p.id end) == [5, 3, 2, 1, 4]
    end

    test "xy_alternating" do
      points = [
        %Asset.Point{id: 1, x: 1, y: 1},
        %Asset.Point{id: 2, x: 2, y: 2},
        %Asset.Point{id: 3, x: 0, y: 10},
        %Asset.Point{id: 4, x: 10, y: 0},
        %Asset.Point{id: 5, x: 10, y: 10}
      ]

      assert Asset.sort_points(points, "xy_alternating")
             |> Enum.map(fn p -> p.id end) == [3, 1, 2, 5, 4]
    end

    test "yx_alternating" do
      points = [
        %Asset.Point{id: 1, x: 1, y: 1},
        %Asset.Point{id: 2, x: 2, y: 2},
        %Asset.Point{id: 3, x: 0, y: 10},
        %Asset.Point{id: 4, x: 10, y: 0},
        %Asset.Point{id: 5, x: 10, y: 10}
      ]

      assert Asset.sort_points(points, "yx_alternating")
             |> Enum.map(fn p -> p.id end) == [4, 1, 2, 5, 3]
    end

    test "random" do
      points = [
        %Asset.Point{id: 1, x: 1, y: 1},
        %Asset.Point{id: 2, x: 2, y: 2},
        %Asset.Point{id: 3, x: 0, y: 10},
        %Asset.Point{id: 4, x: 10, y: 0},
        %Asset.Point{id: 5, x: 10, y: 10}
      ]

      assert Asset.sort_points(points, "random")
             |> Enum.map(fn p -> p.id end)
             |> Enum.count() == 5
    end

    test "nn" do
      points = [
        %Asset.Point{id: 1, x: 1, y: 1},
        %Asset.Point{id: 2, x: 2, y: 2},
        %Asset.Point{id: 3, x: 0, y: 10},
        %Asset.Point{id: 4, x: 10, y: 0},
        %Asset.Point{id: 5, x: 10, y: 10}
      ]

      assert Asset.sort_points(points, "nn")
             |> Enum.map(fn p -> p.id end) == [1, 2, 3, 5, 4]
    end

    test "nn with no points" do
      assert Asset.sort_points([], "nn") == []
    end
  end
end
