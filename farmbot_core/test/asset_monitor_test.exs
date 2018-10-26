defmodule Farmbot.AssetMonitorTest do
  use ExUnit.Case
  alias Farmbot.Asset
  alias Farmbot.AssetSupervisor
  import Farmbot.TestSupport.AssetFixtures
  alias Farmbot.TestSupport.CeleryScript.TestIOLayer

  describe "persistent regimens" do
    test "adding a persistent regimen starts a process" do
      seq = sequence()
      reg = regimen(%{regimen_items: [%{time_offset: 100, sequence_id: seq.id}]})
      event = regimen_event(reg)
      {:ok, pr} = Asset.upsert_persistent_regimen(reg, event)

      Farmbot.AssetMonitor.force_checkup()

      pid = AssetSupervisor.whereis_child(pr)
      assert is_pid(pid)
      assert Process.alive?(pid)

      Asset.Repo.delete!(pr)

      Farmbot.AssetMonitor.force_checkup()
      refute Process.alive?(pid)
    end
  end

  describe "farm events" do
    test "adding a farm event starts a process" do
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

      event = sequence_event(seq, params)

      Farmbot.AssetMonitor.force_checkup()

      pid = AssetSupervisor.whereis_child(event)
      assert is_pid(pid)
      assert Process.alive?(pid)

      Asset.Repo.delete!(event)

      Farmbot.AssetMonitor.force_checkup()
      refute Process.alive?(pid)
    end
  end
end
