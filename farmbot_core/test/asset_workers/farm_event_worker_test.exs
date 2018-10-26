defmodule Farmbot.FarmEventWorkerTest do
  use ExUnit.Case
  alias Farmbot.Asset.FarmEvent

  import Farmbot.TestSupport.AssetFixtures
  alias Farmbot.TestSupport.CeleryScript.TestIOLayer
  import Farmbot.TestSupport

  describe "regimens" do
    test "always ensure a regimen is started"
  end

  describe "sequences" do
    test "doesn't execute a sequence more than 2 mintues late"
  end

  describe "common" do
    test "schedules an event in the future" do
      TestIOLayer.subscribe()
      ast = TestIOLayer.debug_ast()
      seq = sequence(%{body: [ast]})
      now = DateTime.utc_now()
      start_time = Timex.shift(now, seconds: 2)
      end_time = Timex.shift(now, minutes: 10)
      params = %{
        start_time: start_time,
        end_time: end_time,
        repeat: 1,
        time_unit: "minutely"
      }
      assert %FarmEvent{} = sequence_event(seq, params)
      assert_receive ^ast, farm_event_timeout()
    end

    test "wont start an event after end_time" do
        TestIOLayer.subscribe()
        ast = TestIOLayer.debug_ast()
        seq = sequence(%{body: [ast]})
        now = DateTime.utc_now()
        start_time = Timex.shift(now, seconds: 2)
        end_time = Timex.shift(now, minutes: -10)
        params = %{
          start_time: start_time,
          end_time: end_time,
          repeat: 1,
          time_unit: "minutely"
        }
        assert %FarmEvent{} = sequence_event(seq, params)
        refute_receive ^ast
    end
  end
end
