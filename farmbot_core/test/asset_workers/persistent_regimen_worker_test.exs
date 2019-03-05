defmodule FarmbotCore.PersistentRegimenWorkerTest do
  use ExUnit.Case, async: true

  alias FarmbotCore.Asset.PersistentRegimen

  import Farmbot.TestSupport.AssetFixtures

  test "regimen executes a sequence" do
    now = DateTime.utc_now()
    start_time = Timex.shift(now, minutes: -20)
    end_time = Timex.shift(now, minutes: 10)
    {:ok, epoch} = PersistentRegimen.build_epoch(now)
    offset = Timex.diff(now, epoch, :milliseconds) + 500

    seq = sequence()
    regimen_params = %{regimen_items: [%{sequence_id: seq.id, time_offset: offset}]}

    farm_event_params = %{
      start_time: start_time,
      end_time: end_time,
      repeat: 1,
      time_unit: "never"
    }

    pr = persistent_regimen(regimen_params, farm_event_params)

    test_pid = self()

    args = [
      apply_sequence: fn _seq ->
        send(test_pid, :executed)
      end
    ]

    {:ok, _} = FarmbotCore.AssetWorker.FarmbotCore.Asset.PersistentRegimen.start_link(pr, args)
    assert_receive :executed
  end
end
