defmodule SequenceTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "builds a Sequence" do
    {:ok, not_fail} =
      Sequence.create(%{
        "args" => %{},
        "body" => [],
        "color" => "gray",
        "device_id" => 5,
        "kind" => "sequence",
        "id" => 5,
        "name" => "hey"
        })
     assert not_fail.name == "hey"
     assert not_fail.device_id == 5
     assert not_fail.id == 5
  end

  test "does not build a Sequence" do
    fail = Sequence.create(%{"fake" => "Sequence"})
    also_fail = Sequence.create(:wrong_type)
    assert(fail == {Sequence, :malformed})
    assert(also_fail == {Sequence, :malformed})
  end

  test "raises an exception if invalid" do
    assert_raise RuntimeError, "Malformed #{Sequence} Object", fn ->
      Sequence.create!(%{"fake" => "Sequence"})
    end
  end
end
