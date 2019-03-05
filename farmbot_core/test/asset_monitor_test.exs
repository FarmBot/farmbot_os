defmodule FarmbotCore.AssetMonitorTest do
  use ExUnit.Case, async: false
  alias FarmbotCore.{Asset.Repo, AssetMonitor, AssetSupervisor}
  import Farmbot.TestSupport.AssetFixtures

  describe "persistent regimens" do
    test "adding a persistent regimen starts a process" do
      farm_event_params = %{
        start_time: DateTime.utc_now(),
        end_time: DateTime.utc_now(),
        repeat: 1,
        time_unit: "never"
      }

      pr = persistent_regimen(%{}, farm_event_params, %{monitor: true})

      AssetMonitor.force_checkup()

      assert {id, _, _, _} = AssetSupervisor.whereis_child(pr)
      assert id == pr.local_id

      Repo.delete!(pr)

      AssetMonitor.force_checkup()

      assert {id, :undefined, _, _} = AssetSupervisor.whereis_child(pr)
      assert id == pr.local_id
    end
  end

  describe "farm events" do
    test "adding a farm event starts a process" do
      seq = sequence()
      now = DateTime.utc_now()
      start_time = Timex.shift(now, minutes: -20)
      end_time = Timex.shift(now, minutes: 10)

      params = %{
        monitor: true,
        start_time: start_time,
        end_time: end_time,
        repeat: 5,
        time_unit: "hourly"
      }

      event = sequence_event(seq, params)

      AssetMonitor.force_checkup()

      assert {id, _, _, _} = AssetSupervisor.whereis_child(event)
      assert id == event.local_id

      Repo.delete!(event)

      AssetMonitor.force_checkup()

      assert {id, :undefined, _, _} = AssetSupervisor.whereis_child(event)
      assert id == event.local_id
    end
  end
end
