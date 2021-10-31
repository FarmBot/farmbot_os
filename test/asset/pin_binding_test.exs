defmodule FarmbotOS.Asset.PinBindingTest do
  use ExUnit.Case
  alias FarmbotOS.Asset.PinBinding

  @expected_keys [:id, :pin_num, :sequence_id, :special_action]

  test "to_string" do
    proto = String.Chars.FarmbotOS.Asset.PinBinding
    pb1 = %PinBinding{special_action: "emergency_lock", pin_num: 16}
    assert proto.to_string(pb1) == "Button 1: E-Stop (Pi 16)"
    pb2 = %PinBinding{pin_num: 16}
    assert proto.to_string(pb2) == "Button 1:  (Pi 16)"
    pb3 = %PinBinding{special_action: "emergency_unlock", pin_num: 22}
    assert proto.to_string(pb3) == "Button 2: E-Unlock (Pi 22)"
    pb4 = %PinBinding{pin_num: 22}
    assert proto.to_string(pb4) == "Button 2:  (Pi 22)"
    pb5 = %PinBinding{special_action: "power_off", pin_num: 26}
    assert proto.to_string(pb5) == "Button 3: Power Off (Pi 26)"
  end

  test "render/1" do
    result = PinBinding.render(%PinBinding{})
    mapper = fn key -> assert Map.has_key?(result, key) end
    Enum.map(@expected_keys, mapper)
  end
end
