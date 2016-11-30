defmodule ToolTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "builds a Tool" do
    t = %{
      "id" => 1,
      "name" => "tool3",
      "slot_id" => 13,
      }
    {:ok, not_fail} = Tool.create(t)
    assert Tool.create!(t) == not_fail
    assert not_fail.id == 1
    assert not_fail.name == "tool3"
    assert not_fail.slot_id == 13
  end

  test "does not build a Tool" do
    fail = Tool.create(%{"fake" => "Tool"})
    also_fail = Tool.create(:wrong_type)
    assert(fail == {Tool, :malformed})
    assert(also_fail == {Tool, :malformed})
  end

  test "raises an exception if invalid" do
    assert_raise RuntimeError, "Malformed #{Tool} Object", fn ->
      Tool.create!(%{"fake" => "Tool"})
    end
  end
end
