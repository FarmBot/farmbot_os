defmodule FarmbotCeleryScript.SchedulerTest do
  use ExUnit.Case
  alias FarmbotCeleryScript.{Scheduler, AST}
  alias Farmbot.TestSupport.CeleryScript.TestSysCalls

  setup do
    {:ok, shim} = TestSysCalls.checkout()
    {:ok, sch} = Scheduler.start_link([registry_name: :"#{:random.uniform()}"], [])
    [shim: shim, sch: sch]
  end

  test "schedules a sequence to run in the future", %{sch: sch} do
    ast =
      AST.Factory.new()
      |> AST.Factory.rpc_request("hello world")
      |> AST.Factory.read_pin(9, 0)

    pid = self()

    :ok =
      TestSysCalls.handle(TestSysCalls, fn
        :read_pin, args ->
          send(pid, {:read_pin, args})
          1
      end)

    scheduled_time = DateTime.utc_now() |> DateTime.add(100, :millisecond)
    {:ok, _} = Scheduler.schedule(sch, ast, scheduled_time, %{})
    # Hack to force the scheduler to checkup instead of waiting the normal 15 seconds
    send(sch, :checkup)
    assert_receive {:read_pin, [9, 0]}, 1000
  end
end
