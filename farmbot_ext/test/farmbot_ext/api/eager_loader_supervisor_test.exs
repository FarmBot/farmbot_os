defmodule FarmbotExt.API.EagerLoader.SupervisorTest do
  use ExUnit.Case, async: false

  alias FarmbotExt.API.EagerLoader.Supervisor

  test "children" do
    results = Supervisor.children()
    expected = []
    assert results == expected
  end
end
