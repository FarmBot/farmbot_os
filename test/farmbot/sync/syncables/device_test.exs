defmodule DeviceTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "builds a device" do
    not_fail =
      Device.create(%{
        "id" => 123,
        "planting_area_id" => 321,
        "name" => "lunch_time",
        "webcam_url" => nil
        })
    assert(not_fail.id == 123)
    assert(not_fail.planting_area_id == 321)
    assert(not_fail.name == "lunch_time")
    assert(not_fail.webcam_url == nil)
  end

  test "does not build a device" do
    fail = Device.create(%{"fake" => "device"})
    also_fail = Device.create(:wrong_type)
    assert(fail == :error)
    assert(also_fail == :error)
  end
end
