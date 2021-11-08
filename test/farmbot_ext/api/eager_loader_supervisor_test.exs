defmodule FarmbotOS.EagerLoader.SupervisorTest do
  use ExUnit.Case

  alias FarmbotOS.EagerLoader.Supervisor

  test "children" do
    results = Supervisor.children()
    expected = []
    assert results == expected
  end
end
