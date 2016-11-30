defmodule RegimenTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "builds a Regimen" do
    {:ok, not_fail} =
      Regimen.create(%{
        "id" => 1,
        "device_id" => 1,
        "color" => "purple",
        "name" => "close the door its cold in here."
        })
    assert not_fail.id == 1
    assert not_fail.device_id == 1
    assert not_fail.color == "purple"
    assert not_fail.name == "close the door its cold in here."
  end

  test "does not build a Regimen" do
    fail = Regimen.create(%{"fake" => "corpus"})
    also_fail = Regimen.create(:wrong_type)
    assert(fail == {Regimen, :malformed})
    assert(also_fail == {Regimen, :malformed})
  end

  test "raises an exception if invalid" do
    assert_raise RuntimeError, "Malformed #{Regimen} Object", fn ->
      Regimen.create!(%{"fake" => "Regimen"})
    end
  end
end
