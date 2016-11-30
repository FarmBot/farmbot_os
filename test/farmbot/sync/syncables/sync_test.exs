defmodule SyncTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "builds a sync object" do
    {:ok, s} =
      Sync.create(
        %{"compat_num" => 154,
          "device" =>
            %{"id" => 1000,
              "planting_area_id" => nil,
              "name" => "something_clever",
              "webcam_url" => nil},
          "peripherals" => [],
          "plants" => [],
          "regimen_items" => [],
          "regimens" => [],
          "sequences" => [],
          "users" => [],
          "tool_bays" => [],
          "tools" => [],
          "tool_slots" => []})
    assert s.compat_num == 154
    assert s.peripherals == []
    assert s.plants == []
    assert s.regimens == []
    assert s.regimen_items == []
    assert s.users == []
    assert s.tool_bays == []
    # assert s.tools == []
    # assert s.tool_slots == []
    assert s.device ==
      %Device{id: 1000,
              planting_area_id: nil,
              name: "something_clever",
              webcam_url: nil}
  end

  test "does not build a sync object" do
    fail = Sync.create(%{"fake" => "corpus"})
    also_fail = Sync.create(:wrong_type)
    assert(fail == {Sync, :malformed})
    assert(also_fail == {Sync, :malformed})
  end

  test "raises an exception for a malformed embedded object" do
    Sync.create!(
      %{"compat_num" => 154,
        "device" =>
          %{"id" => 1000,
            "planting_area_id" => nil,
            "name" => "something_clever",
            "webcam_url" => nil,
            "home_address" => "1600 Pennsylvania Ave NW, Washington, DC 20500"},
        "peripherals" => [],
        "plants" => [],
        "regimen_items" => [],
        "regimens" => [],
        "sequences" => [],
        "users" => [],
        "tool_bays" => [],
        "tools" => [],
        "tool_slots" => []})
  end

  test "raises an exception if invalid" do
    assert_raise RuntimeError, "Malformed #{Sync} Object", fn ->
      Sync.create!(%{"fake" => "corpus"})
    end
  end
end
