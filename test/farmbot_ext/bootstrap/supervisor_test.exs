defmodule FarmbotExt.Bootstrap.SupervisorTest do
  use ExUnit.Case
  use Mimic

  setup :verify_on_exit!

  test "children" do
    results = FarmbotExt.Bootstrap.Supervisor.children()
    expected = []
    assert results == expected
  end

  test "init" do
    {:ok, pid} = FarmbotExt.Bootstrap.Supervisor.start_link([], [])
    Process.exit(pid, :normal)
  end
end
