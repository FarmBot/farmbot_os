defmodule FarmbotCore.FarmEventWorkerTest do
  use ExUnit.Case, async: true
  alias FarmbotCore.{Asset.FarmEvent, AssetWorker}

  import Farmbot.TestSupport.AssetFixtures

  # Regimen tests are in the RegimenInstanceWorker test

  describe "sequences" do
    test "doesn't execute a sequence more than 2 mintues late" do
      seq = sequence()
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
      test_pid = self()

      args = [
        handle_sequence: fn _sequence ->
          send(test_pid, {:executed, test_pid})
        end
      ]

      {:ok, pid} = AssetWorker.start_link(fe, args)
      send(pid, :timeout)

      # This is not really that useful.
      refute_receive {:executed, ^test_pid}
    end
  end

  describe "common" do
    test "schedules an event in the future" do
      seq = sequence()
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
      test_pid = self()

      args = [
        handle_sequence: fn _sequence ->
          send(test_pid, {:executed, test_pid})
        end
      ]

      {:ok, pid} = AssetWorker.start_link(fe, args)
      send(pid, :timeout)
      assert_receive {:executed, ^test_pid}, 5_000
    end

    test "wont start an event after end_time" do
      seq = sequence()
      now = DateTime.utc_now()
      start_time = Timex.shift(now, minutes: -12)
      end_time = Timex.shift(now, minutes: -10)
      assert Timex.from_now(end_time) == "10 minutes ago"

      params = %{
        start_time: start_time,
        end_time: end_time,
        repeat: 1,
        time_unit: "minutely"
      }

      assert %FarmEvent{} = fe = sequence_event(seq, params)
      # refute FarmEvent.build_calendar(fe, now)
      assert fe.end_time == end_time
      test_pid = self()

      args = [
        handle_sequence: fn _sequence ->
          send(test_pid, {:executed, test_pid})
        end
      ]

      assert :ignore = AssetWorker.start_link(fe, args)
      # This is not really that useful.
      refute_receive {:executed, ^test_pid}, 5_000
    end
  end
end
