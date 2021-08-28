defmodule FarmbotCore.Asset.FarmEvent.CalendarTest do
  use ExUnit.Case
  alias FarmbotCore.Asset.FarmEvent.Calendar

  describe "calendar" do
    test "generation of a calendar" do
      current_time_seconds = 1_630_165_395
      end_time_seconds = 1_630_169_100
      repeat = 1
      repeat_frequency_seconds = 60
      start_time_seconds = 1_630_165_500

      calendar =
        Calendar.new(
          current_time_seconds,
          end_time_seconds,
          repeat,
          repeat_frequency_seconds,
          start_time_seconds
        )

      assert Enum.count(calendar) == 60

      assert Enum.take(calendar, 5) == [
               1_630_165_500,
               1_630_165_560,
               1_630_165_620,
               1_630_165_680,
               1_630_165_740
             ]
    end
  end
end
