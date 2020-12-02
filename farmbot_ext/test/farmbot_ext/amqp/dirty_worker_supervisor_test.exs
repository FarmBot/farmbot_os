defmodule FarmbotExt.API.DirtyWorker.SupervisorTest do
  use ExUnit.Case, async: false
  use Mimic

  alias FarmbotExt.API.DirtyWorker.Supervisor

  setup :verify_on_exit!

  test "children" do
    results = Supervisor.children()
    expected = []
    assert results == expected
  end
end
