defmodule FarmbotOS.Asset.PeripheralTest do
  use ExUnit.Case
  alias FarmbotOS.Asset.Peripheral

  @expected_keys [:id, :pin, :mode, :label]

  test "to_string - %Peripheral{}" do
    pin = 1
    label = "foo"
    peripheral = %Peripheral{pin: pin, label: label}
    proto = String.Chars.FarmbotOS.Asset.Peripheral
    expected = "Peripheral #{label} Pin: #{pin}"
    actual = proto.to_string(peripheral)
    assert expected == actual
  end

  test "render/1" do
    result = Peripheral.render(%Peripheral{})
    mapper = fn key -> assert Map.has_key?(result, key) end
    Enum.map(@expected_keys, mapper)
  end
end
