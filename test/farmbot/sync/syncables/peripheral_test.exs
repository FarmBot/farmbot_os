defmodule PeripheralTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "builds a Peripheral" do
    not_fail =
      Peripheral.create(%{
        "id" => 123,
        "device_id" => 965,
        "pin" => 25,
        "mode" => 0,
        "label" => "laser beam",
        "created_at" => "timestamp hur hur hur",
        "updated_at" => "timestamp hur hur hur"})
    assert(not_fail.id == 123)
    assert(not_fail.device_id == 965)
    assert(not_fail.pin == 25)
    assert(not_fail.mode == 0)
    assert(not_fail.label == "laser beam")
    assert(not_fail.created_at == "timestamp hur hur hur")
    assert(not_fail.updated_at == "timestamp hur hur hur")
  end

  test "does not build a Peripheral" do
    fail = Peripheral.create(%{"fake" => "Peripheral"})
    also_fail = Peripheral.create(:wrong_type)
    assert(fail == :error)
    assert(also_fail == :error)
  end
end
