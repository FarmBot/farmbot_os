defmodule PlantTest do
  @moduledoc false
  use ExUnit.Case, async: true

  # i really need the coverage
  test "builds a plant" do
    {:ok, f} = Plant.create(%{"this" => "is a stub"})
    assert is_map(f) == true
    a = Plant.create!(%{"fixme" => "but later"})
    assert is_map(a) == true
  end

  test "does not build a Plant" do
    also_fail = Plant.create(:wrong_type)
    assert(also_fail == {Plant, :malformed})
  end

  test "raises an exception if invalid" do
    assert_raise RuntimeError, "Malformed #{Plant} Object", fn ->
      Plant.create!(:fail)
    end
  end
end
