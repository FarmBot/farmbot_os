defmodule Farmbot.BotState.LocationDataTest do
  @moduledoc "Tests location data."

  use ExUnit.Case
  alias Farmbot.BotState.LocationData

  test "builds new vec3" do
    alias LocationData.Vec3
    vec3 = %Vec3{x: -1, y: -2, z: 123}
    assert match?(^vec3, Vec3.new(-1, -2, 123))
  end
end
