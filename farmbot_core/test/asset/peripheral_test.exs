defmodule FarmbotCore.Asset.PeripheralTest do
  use ExUnit.Case
  alias FarmbotCore.Asset.Peripheral

  @expected_keys [:id, :pin, :mode, :label]

  test "render/1" do
    result = Peripheral.render(%Peripheral{})
    mapper = fn key -> assert Map.has_key?(result, key) end
    Enum.map(@expected_keys, mapper)
  end
end
