defmodule FarmbotCore.Asset.FarmEventTest do
  use ExUnit.Case, async: true
  alias FarmbotCore.Asset.FarmEvent

  @expected_keys [
    :id,
    :end_time,
    :executable_type,
    :executable_id,
    :repeat,
    :start_time,
    :time_unit,
    :body
  ]

  test "render/1" do
    result = FarmEvent.render(%FarmEvent{})
    mapper = fn key -> assert Map.has_key?(result, key) end
    Enum.map(@expected_keys, mapper)
  end
end
