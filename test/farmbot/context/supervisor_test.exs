defmodule SomeSupervisorProcess do
  use Farmbot.Context.Supervisor
end

defmodule Farmbot.Context.SupervisorTest do
  use ExUnit.Case, async: true
  alias Farmbot.Context

  setup_all do
    ctx = Context.new()
    [cs_context: ctx]
  end

  test "Builds a context tracker", %{cs_context: ctx} do
    {:ok, pid} = SomeSupervisorProcess.start_link(ctx, [])
    assert is_pid(pid)
    assert Process.alive?(pid)
  end

  test "Does gud pattern matching", %{cs_context: ctx} do
    assert_raise FunctionClauseError, fn() ->
      not_quite_context = Map.from_struct(ctx)
      SomeSupervisorProcess.start_link(not_quite_context, [])
    end
  end
end
