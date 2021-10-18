defmodule FarmbotCore.Asset.PointTest do
  use ExUnit.Case
  alias FarmbotCore.Asset.Point

  @expected_keys [
    :id,
    :meta,
    :name,
    :plant_stage,
    :created_at,
    :updated_at,
    :planted_at,
    :pointer_type,
    :radius,
    :tool_id,
    :discarded_at,
    :gantry_mounted,
    :openfarm_slug,
    :pullout_direction,
    :x,
    :y,
    :z
  ]

  test "render/1" do
    result = Point.render(%Point{})
    mapper = fn key -> assert Map.has_key?(result, key) end
    Enum.map(@expected_keys, mapper)
  end
end
