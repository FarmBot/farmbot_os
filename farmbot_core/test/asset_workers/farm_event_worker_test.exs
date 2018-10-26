defmodule Farmbot.FarmEventWorkerTest do
  use ExUnit.Case
  alias Farmbot.Asset.FarmEvent

  import Farmbot.TestSupport.AssetFixtures
  alias Farmbot.TestSupport.CeleryScript.TestIOLayer
  import Farmbot.TestSupport

  describe "regimens" do
    test "always ensure a regimen is started" do
      seq = sequence()
      reg = regimen(%{regimen_items: [%{time_offset: 100, sequence_id: seq.id}]})

      now = DateTime.utc_now()
      start_time = Timex.shift(now, minutes: -20)
      end_time = Timex.shift(now, minutes: 10)
      params = %{
        start_time: start_time,
        end_time: end_time,
        repeat: 1,
        time_unit: "never"
      }
      _event = regimen_event(reg, params)
      refute :lookup_persistent_regimen_after_sleep?
    end
  end

  describe "sequences" do
    # TODO(Connor) - this test isn't really that good
    # Because it is timeout based..
    test "doesn't execute a sequence more than 2 mintues late" do
      TestIOLayer.subscribe()
      ast = TestIOLayer.debug_ast()
      seq = sequence(%{body: [ast]})
      now = DateTime.utc_now()
      start_time = Timex.shift(now, minutes: -20)
      end_time = Timex.shift(now, minutes: 10)
      params = %{
        start_time: start_time,
        end_time: end_time,
        repeat: 1,
        time_unit: "never"
      }
      assert %FarmEvent{} = sequence_event(seq, params)
      # This is not really that useful.
      refute_receive ^ast, farm_event_timeout()
    end
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
        # This is not really that useful.
        refute_receive ^ast
    end
  end
end
