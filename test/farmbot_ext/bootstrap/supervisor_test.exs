defmodule FarmbotOS.Bootstrap.SupervisorTest do
  use ExUnit.Case
  use Mimic

  setup :verify_on_exit!

  test "children" do
    results = FarmbotOS.Bootstrap.Supervisor.children()
    expected = []
    assert results == expected
  end

  test "init" do
    {:ok, pid} = FarmbotOS.Bootstrap.Supervisor.start_link([], [])
    Process.exit(pid, :normal)
  end
end
