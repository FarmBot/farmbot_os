defmodule FarmbotCeleryScript.DotPropsTest do
  use ExUnit.Case
  alias FarmbotCeleryScript.DotProps

  test "converts dotted props to real nested maps" do
    assert %{"foo" => "bar"} == DotProps.create("foo", "bar")
  end
end
