defmodule FarmbotExt.FarmbotExtTest do
  use ExUnit.Case

  test "provides default values for mocks" do
    default = FarmbotExt.fetch_impl!(__MODULE__, :xyz, SensibleDefault)
    assert default === SensibleDefault
  end
end
