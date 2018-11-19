defmodule Farmbot.PersistentRegimenWorkerTest do
  use ExUnit.Case, async: true
  alias Farmbot.{Asset.FarmEvent, Asset.PersistentRegimen}
  import Farmbot.TestSupport.AssetFixtures
  alias Farmbot.TestSupport.CeleryScript.TestIOLayer
  import Farmbot.TestSupport

  test "regimen executes a sequence" do
    now = DateTime.utc_now()
    start_time = Timex.shift(now, minutes: -20)
    end_time = Timex.shift(now, minutes: 10)
    {:ok, epoch} = PersistentRegimen.build_epoch(now)
    offset = Timex.diff(now, epoch, :milliseconds) + 500

    TestIOLayer.subscribe()
    ast = TestIOLayer.debug_ast()
    seq = sequence(%{body: [ast]})

    reg = regimen(%{regimen_items: [%{time_offset: offset, sequence_id: seq.id}]})

    params = %{
      start_time: start_time,
      end_time: end_time,
      repeat: 1,
      time_unit: "never"
    }

    assert %FarmEvent{} = fe = regimen_event(reg, params)

    {:ok, pid} = Farmbot.AssetWorker.start_link(fe)
    Farmbot.AssetWorker.Farmbot.Asset.FarmEvent.force_checkup(pid)
    assert_receive ^ast, farm_event_timeout() + persistent_regimen_timeout() + 5000
  end
end
