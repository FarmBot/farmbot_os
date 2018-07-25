defmodule FarmbotExtTest do
  use ExUnit.Case
  doctest FarmbotExt

  test "greets the world" do
    assert FarmbotExt.hello() == :world
  end
end
