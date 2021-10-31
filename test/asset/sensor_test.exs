defmodule FarmbotOS.Asset.SensorTest do
  use ExUnit.Case

  alias FarmbotOS.Asset.Sensor

  test "changeset" do
    s = %Sensor{id: 123, pin: 456, mode: 0}
    result = Sensor.render(s)
    assert s.id == result[:id]
    assert s.pin == result[:pin]
    assert s.mode == result[:mode]
  end
end
