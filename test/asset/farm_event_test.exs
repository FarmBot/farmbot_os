defmodule FarmbotOS.Asset.FarmEventTest do
  use ExUnit.Case
  alias FarmbotOS.Asset.FarmEvent

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

  test "build_calendar" do
    expected1 = ~U[2020-12-09 17:18:00.000000Z]
    fe1 = %FarmEvent{executable_type: "Regimen", start_time: expected1}
    actual1 = Enum.at(FarmEvent.build_calendar(fe1, nil), 0)
    assert expected1 == actual1

    expected2 = ~U[2021-12-09 17:18:00.000000Z]
    fe2 = %FarmEvent{time_unit: "never", start_time: expected2}
    actual2 = Enum.at(FarmEvent.build_calendar(fe2, nil), 0)
    assert expected2 == actual2
  end
end
