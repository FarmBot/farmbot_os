defmodule Farmbot.Database.SelectorsTest do
  @moduledoc "Tests selectors."

  use ExUnit.Case
  alias Farmbot.Database.RecordStorage, as: RS
  alias Farmbot.Database.Syncable
  alias Syncable.Point
  alias Syncable.Tool
  alias Farmbot.Database.Selectors
  alias Selectors.Error, as: SelectorError

  setup do
    {:ok, rs} = RS.start_link([])
    [
      %Point{
        pointer_type: "Plant",
        created_at: nil,
        tool_id: nil,
        radius: 5,
        name: "Cabbage",
        meta: nil,
        x: 0,
        y: 1,
        z: 2,
        id: 1
      },

      %Tool{
        name: "Laser Beam",
        status: "idle",
        id: 9000
      },

      %Point{
        pointer_type: "ToolSlot",
        created_at: nil,
        tool_id: 9000,
        radius: 5,
        name: "Laser Beam holder",
        meta: nil,
        x: 0,
        y: 10,
        z: 10,
        id: 2
      },

      %Point{
        pointer_type: "GenericPointer",
        created_at: nil,
        tool_id: nil,
        radius: 5,
        name: "Hole in the bed",
        meta: nil,
        x: 123,
        y: 222,
        z: 0,
        id: 3
      },

    ] |> RS.commit_records(rs)
    [rs: rs]
  end

  test "finds a plant", ctx do
    r = Selectors.find_point(ctx.rs, "Plant", 1)
    assert r == %Syncable{body: %Point{
            pointer_type: "Plant",
            created_at: nil,
            tool_id: nil,
            radius: 5,
            name: "Cabbage",
            meta: nil,
            x: 0,
            y: 1,
            z: 2,
            id: 1
          }, ref_id: {Point, -1, 1}}
  end

  test "finds a toolslot", ctx do
    r = Selectors.find_point(ctx.rs, "GenericPointer", 3)
    assert r == %Syncable{body: %Point{
            pointer_type: "GenericPointer",
            created_at: nil,
            tool_id: nil,
            radius: 5,
            name: "Hole in the bed",
            meta: nil,
            x: 123,
            y: 222,
            z: 0,
            id: 3
          }, ref_id: {Point, -1, 3}}
  end

  test "finds an uncatagorized pointer.", ctx do
    r = Selectors.find_point(ctx.rs, "ToolSlot", 2)
    assert r == %Syncable{body: %Point{
            pointer_type: "ToolSlot",
            created_at: nil,
            tool_id: 9000,
            radius: 5,
            name: "Laser Beam holder",
            meta: nil,
            x: 0,
            y: 10,
            z: 10,
            id: 2
          }, ref_id: {Point, -1, 2}}
  end

  test "raises when requesting the wrong type", ctx do
    assert_raise SelectorError, "does not match type: ToolSlot", fn() ->
      Selectors.find_point(ctx.rs, "ToolSlot", 1)
    end
  end

  alias Syncable.Device
  test "Gets the db entry for this device.", ctx do
    device_record = %Device{name: "farmbot_negative_one", timezone: nil, id: 1}
    RS.commit_records(device_record, ctx.rs)
    device = Selectors.get_device(ctx.rs)
    assert device.name == "farmbot_negative_one"
  end

  test "raises if there is more than one device", ctx do
    device_record_1 = %Device{name: "farmbot_negative_one", timezone: nil, id: 1}
    device_record_2 = %Device{name: "farmbot_negative_two", timezone: nil, id: 2}
    RS.commit_records([device_record_1, device_record_2], ctx.rs)
    assert_raise SelectorError, "Too many devices.", fn() ->
      IO.inspect Selectors.get_device(ctx.rs)
    end
  end

  test "raises if there is no device", ctx do
    assert_raise SelectorError, "No device.", fn() ->
      Selectors.get_device(ctx.rs)
    end
  end
end
