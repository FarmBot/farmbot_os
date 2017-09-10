defmodule Farmbot.Database.Syncable.PointTest do
  @moduledoc "Tests point funs."

  alias Farmbot.Database.{Syncable, Selectors}
  alias Selectors.Error, as: SelectorError
  alias Syncable.{Point, Tool}
  alias Farmbot.Database.RecordStorage, as: RS

  use ExUnit.Case

  setup do
    {:ok, rs} = RS.start_link([])
    [rs: rs]
  end

  test "gets a tool by id", ctx do
    [
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
    ] |> RS.commit_records(ctx.rs)
    assert Point.get_tool(ctx.rs, 9000) == %Syncable{body: %Point{
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

  test "Raises when a tool doesn't exist", ctx do
    assert_raise SelectorError, "Could not find tool_slot with tool_id: 1234",
      fn() ->
        Point.get_tool(ctx.rs, 1234)
      end
  end

end
