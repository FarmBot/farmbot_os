defmodule RegimenItemTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "builds a RegimenItem" do
    {:ok, not_fail} =
      RegimenItem.create(%{
        "id" => 123,
        "time_offset" => 456,
        "regimen_id" => 234,
        "sequence_id" => 111
        })
    assert not_fail.id == 123
    assert not_fail.time_offset == 456
    assert not_fail.regimen_id == 234
    assert not_fail.sequence_id == 111
  end

  test "does not build a RegimenItem" do
    fail = RegimenItem.create(%{"fake" => "corpus"})
    also_fail = RegimenItem.create(:wrong_type)
    assert(fail == {RegimenItem, :malformed})
    assert(also_fail == {RegimenItem, :malformed})
  end

  test "raises an exception if invalid" do
    assert_raise RuntimeError, "Malformed #{RegimenItem} Object", fn ->
      RegimenItem.create!(%{"fake" => "RegimenItem"})
    end
  end
end
