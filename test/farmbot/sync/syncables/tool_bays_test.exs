defmodule ToolbayTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "builds a toolbay" do
    tb = %{
      "created_at" => "2016-11-30T15:20:52.307Z",
      "updated_at" => "2016-11-30T15:20:52.307Z",
      "device_id" => 123,
      "id" => 845,
      "name" => "San Francisco" # <= get it???
      }
    {:ok, not_fail} =
      Toolbay.create(tb)
    assert Toolbay.create!(tb) == not_fail
    assert not_fail.created_at == "2016-11-30T15:20:52.307Z"
    assert not_fail.updated_at == "2016-11-30T15:20:52.307Z"
    assert not_fail.device_id == 123
    assert not_fail.id == 845
    assert not_fail.name == "San Francisco"
  end

  test "does not build a toolbay" do
    fail = Toolbay.create(%{"fake" => "corpus"})
    also_fail = Toolbay.create(:wrong_type)
    assert(fail == {Toolbay, :malformed})
    assert(also_fail == {Toolbay, :malformed})
  end

  test "raises an exception if invalid" do
    assert_raise RuntimeError, "Malformed #{Toolbay} Object", fn ->
      Toolbay.create!(%{"fake" => "corpus"})
    end
  end
end
