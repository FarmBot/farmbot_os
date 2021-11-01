defmodule FarmbotOS.Asset.SensorReadingTest do
  use ExUnit.Case

  alias FarmbotOS.Asset.SensorReading

  test "changeset" do
    s = %SensorReading{
      id: 0,
      mode: 1,
      pin: 2,
      value: 3,
      x: 4,
      y: 5,
      z: 7
    }

    result = SensorReading.render(s)
    assert s.id == result[:id]
    assert s.mode == result[:mode]
    assert s.pin == result[:pin]
    assert s.value == result[:value]
    assert s.x == result[:x]
    assert s.y == result[:y]
    assert s.z == result[:z]
  end
end
