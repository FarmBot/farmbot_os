defmodule FarmbotOS.FarmEventWorker.SequenceTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.FarmEventWorker.SequenceEvent
  alias FarmbotOS.Asset

  test "init/1" do
    arry = [:farm_event, :args]
    {:ok, %{farm_event: :farm_event, args: :args}} = SequenceEvent.init(arry)
    assert_receive :schedule, 1000
  end

  test "handle_info(:schedule, state)" do
    state = %{
      args: [],
      farm_event: %FarmbotOS.Asset.FarmEvent{
        body: [],
        created_at: ~U[2021-10-08 21:28:19.200000Z],
        end_time: ~U[2051-10-09 22:30:00.000000Z],
        executable_id: 2,
        executable_type: "Sequence",
        executions: [],
        id: 1,
        last_executed: nil,
        local_id: "6fae5451-baa8-4368-9612-cfd571384814",
        repeat: 1,
        start_time: ~U[2051-10-08 21:30:00.000000Z],
        time_unit: "hourly",
        updated_at: ~U[2051-10-08 21:28:19.294000Z]
      },
      scheduled: 25,
      timesync_waits: 0
    }

    expect(FarmbotOS.Celery, :schedule, 25, fn celery_ast, _at, farm_event ->
      assert %FarmbotOS.Celery.AST{} = celery_ast
      assert state.farm_event.id == farm_event.id
      :ok
    end)

    expect(Asset, :get_sequence, 25, fn executable_id ->
      assert executable_id == 2

      %{
        name: "Test sequence",
        id: 44,
        kind: "sequence",
        args: %{locals: %{kind: :scope_declaration, args: %{}, body: []}},
        body: []
      }
    end)

    {:noreply, state2} = SequenceEvent.handle_info(:schedule, state)

    assert state2.farm_event.local_id == state2.farm_event.local_id
    assert state2.scheduled == 50
    assert state2.timesync_waits == 0
  end
end
