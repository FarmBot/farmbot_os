defmodule FarmbotOS.Celery.SchedulerTest do
  use ExUnit.Case
  use Mimic
  alias FarmbotOS.Celery.{Scheduler, AST}
  alias FarmbotOS.Celery.SysCallGlue.Stubs
  import ExUnit.CaptureLog

  setup :set_mimic_global
  setup :verify_on_exit!

  test "schedules a sequence to run in the future" do
    expect(Stubs, :read_pin, 1, fn _num, _mode ->
      23
    end)

    {:ok, sch} = Scheduler.start_link([registry_name: :"#{UUID.uuid1()}"], [])

    ast =
      AST.Factory.new()
      |> AST.Factory.rpc_request("hello world")
      |> AST.Factory.read_pin(9, 0)

    scheduled_time = DateTime.utc_now() |> DateTime.add(100, :millisecond)
    # msg = "[info]  Next execution is ready for execution: now"
    {:ok, _} = Scheduler.schedule(sch, ast, scheduled_time, %{})

    # Hack to force the scheduler to checkup instead of waiting the normal 15 seconds
    assert capture_log(fn ->
             send(sch, :checkup)
             # Sorry.
             Process.sleep(1100)
           end) =~ "[info]  Next execution is ready for execution: now"
  end
end
