defmodule Farmbot.BotState.LocationDataTest do
  @moduledoc "Tests location data."

  use ExUnit.Case
  alias Farmbot.BotState
  alias Farmbot.BotState.LocationData
  alias LocationData.Vec3

  setup do
    {:ok, bot_state_tracker} = BotState.start_link()
    {:ok, location_data} = LocationData.start_link(bot_state_tracker, [])
    [location_data: location_data, bot_state_tracker: bot_state_tracker]
  end

  test "builds new vec3" do
    vec3 = %Vec3{x: -1, y: -2, z: 123}
    assert match?(^vec3, Vec3.new(-1, -2, 123))
  end

  test "updates position", ctx do
    LocationData.report_current_position(ctx.location_data, 1, 2, 3)
    assert :sys.get_state(ctx.location_data).public.position == %Vec3{x: 1, y: 2, z: 3}

    assert :sys.get_state(ctx.bot_state_tracker).bot_state.location_data.position == %Vec3{
             x: 1,
             y: 2,
             z: 3
           }
  end

  test "updates scaled_encoders", ctx do
    LocationData.report_encoder_position_scaled(ctx.location_data, 1, 2, 3)
    assert :sys.get_state(ctx.location_data).public.scaled_encoders == %Vec3{x: 1, y: 2, z: 3}

    assert :sys.get_state(ctx.bot_state_tracker).bot_state.location_data.scaled_encoders == %Vec3{
             x: 1,
             y: 2,
             z: 3
           }
  end

  test "updates raw_encoders", ctx do
    LocationData.report_encoder_position_raw(ctx.location_data, 1, 2, 3)
    assert :sys.get_state(ctx.location_data).public.raw_encoders == %Vec3{x: 1, y: 2, z: 3}

    assert :sys.get_state(ctx.bot_state_tracker).bot_state.location_data.raw_encoders == %Vec3{
             x: 1,
             y: 2,
             z: 3
           }
  end

  test "updates end_stops", ctx do
    LocationData.report_end_stops(ctx.location_data, 1, 1, 0, 0, 1, 0)
    assert :sys.get_state(ctx.location_data).public.end_stops == "110010"
    assert :sys.get_state(ctx.bot_state_tracker).bot_state.location_data.end_stops == "110010"
  end
end
