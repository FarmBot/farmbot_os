defmodule SomeWorkerProcess do
  use Farmbot.Context.Worker
end

defmodule SomeOtherProcess do
  use Farmbot.Context.Worker

  def init(ctx) do
    {:ok, %{context: ctx, blah: :important_state} }
  end
end

defmodule Farmbot.Context.WorkerTest do
  use ExUnit.Case, async: true
  alias Farmbot.Context

  setup_all do
    ctx = Context.new()
    [cs_context: ctx]
  end

  test "Builds a context tracker", %{cs_context: ctx} do
    {:ok, pid} = SomeWorkerProcess.start_link(ctx, [])
    assert is_pid(pid)
    state = :sys.get_state(pid)
    assert state.context == ctx
  end

  test "Does gud pattern matching", %{cs_context: ctx} do
    assert_raise FunctionClauseError, fn() ->
      not_quite_context = Map.from_struct(ctx)
      SomeWorkerProcess.start_link(not_quite_context, [])
    end
  end

  test "allows overwriting `init/1` function", %{cs_context: ctx} do
    {:ok, pid} = SomeOtherProcess.start_link(ctx, [])
    assert is_pid(pid)

    state = :sys.get_state(pid)
    assert state.blah == :important_state
  end
end
