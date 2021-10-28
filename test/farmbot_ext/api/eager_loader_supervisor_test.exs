defmodule FarmbotExt.EagerLoader.SupervisorTest do
  use ExUnit.Case

  alias FarmbotExt.EagerLoader.Supervisor

  test "children" do
    results = Supervisor.children()
    expected = []
    assert results == expected
  end
end
