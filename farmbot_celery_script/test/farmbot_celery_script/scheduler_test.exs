defmodule FarmbotCeleryScript.SchedulerTest do
  use ExUnit.Case
  use Mimic
  alias FarmbotCeleryScript.{Scheduler, AST}
  alias FarmbotCeleryScript.SysCalls.Stubs

  setup :set_mimic_global
  setup :verify_on_exit!

  test "schedules a sequence to run in the future" do
    expect(Stubs, :read_pin, 1, fn _num, _mode ->
      23
    end)

    {:ok, sch} =
      Scheduler.start_link([registry_name: :"#{:random.uniform()}"], [])

    ast =
      AST.Factory.new()
      |> AST.Factory.rpc_request("hello world")
      |> AST.Factory.read_pin(9, 0)

    scheduled_time = DateTime.utc_now() |> DateTime.add(100, :millisecond)
    {:ok, _} = Scheduler.schedule(sch, ast, scheduled_time, %{})

    # Hack to force the scheduler to checkup instead of waiting the normal 15 seconds
    send(sch, :checkup)
    # Sorry.
    Process.sleep(1100)
  end
end
