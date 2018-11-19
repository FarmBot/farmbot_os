defmodule Farmbot.FarmEventWorkerTest do
  use ExUnit.Case, async: true
  alias Farmbot.Asset.FarmEvent

  import Farmbot.TestSupport.AssetFixtures
  alias Farmbot.TestSupport.CeleryScript.TestIOLayer
  import Farmbot.TestSupport

  # Regimen tests are in the PersistentRegimeWorker test

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

      assert %FarmEvent{} = fe = sequence_event(seq, params)
      {:ok, pid} = Farmbot.AssetWorker.start_link(fe)
      Farmbot.AssetWorker.Farmbot.Asset.FarmEvent.force_checkup(pid)

      # This is not really that useful.
      refute_receive ^ast, farm_event_timeout() + 5000
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

      assert %FarmEvent{} = fe = sequence_event(seq, params)
      {:ok, pid} = Farmbot.AssetWorker.start_link(fe)
      Farmbot.AssetWorker.Farmbot.Asset.FarmEvent.force_checkup(pid)
      assert_receive ^ast, farm_event_timeout() + 5000
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

      assert %FarmEvent{} = fe = sequence_event(seq, params)
      {:ok, pid} = Farmbot.AssetWorker.start_link(fe)
      Farmbot.AssetWorker.Farmbot.Asset.FarmEvent.force_checkup(pid)
      # This is not really that useful.
      refute_receive ^ast
    end
  end
end
