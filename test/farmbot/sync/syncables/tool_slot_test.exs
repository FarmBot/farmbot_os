defmodule ToolSlotTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "builds a ToolSlot" do
    ts = %{
      "id" => 1,
      "name" => "slot2",
      "tool_bay_id" => 13,
      "x" => 1,
      "y" => 2,
      "z" => 4
      }
    {:ok, not_fail} = ToolSlot.create(ts)
    assert ToolSlot.create!(ts) == not_fail
    assert not_fail.name == "slot2"
    assert not_fail.tool_bay_id == 13
    assert not_fail.id == 1
    assert not_fail.x == 1
    assert not_fail.y == 2
    assert not_fail.z == 4
  end

  test "does not build a ToolSlot" do
    fail = ToolSlot.create(%{"fake" => "ToolSlot"})
    also_fail = ToolSlot.create(:wrong_type)
    assert(fail == {ToolSlot, :malformed})
    assert(also_fail == {ToolSlot, :malformed})
  end

  test "raises an exception if invalid" do
    assert_raise RuntimeError, "Malformed #{ToolSlot} Object", fn ->
      ToolSlot.create!(%{"fake" => "ToolSlot"})
    end
  end
end
