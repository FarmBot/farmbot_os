defmodule FarmbotExt.API.EagerLoader.SupervisorTest do
  use ExUnit.Case

  alias FarmbotExt.API.EagerLoader.Supervisor

  test "children" do
    results = Supervisor.children()
    expected = []
    assert results == expected
  end
end
