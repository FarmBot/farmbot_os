defmodule FarmbotOS.Asset.DeviceTest do
  use ExUnit.Case
  alias FarmbotOS.Asset.Device

  @expected_keys [
    :id,
    :name,
    :timezone,
    :ota_hour,
    :needs_reset,
    :mounted_tool_id
  ]

  test "render/1" do
    result = Device.render(%Device{})
    mapper = fn key -> assert Map.has_key?(result, key) end
    Enum.map(@expected_keys, mapper)
  end

  test "render - part II" do
    result = FarmbotOS.Asset.View.render(Device, %Device{})
    mapper = fn key -> assert Map.has_key?(result, key) end
    Enum.map(@expected_keys, mapper)
  end
end
