defmodule FarmbotOS.Config.StringValueTest do
  use ExUnit.Case
  alias FarmbotOS.Config.StringValue

  test "changeset" do
    sv = %StringValue{value: "Foo"}
    cs = StringValue.changeset(sv)
    assert cs.data == sv
  end
end
