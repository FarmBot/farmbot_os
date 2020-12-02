defmodule FarmbotOS.Lua.UtilTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotOS.Lua.Util

  test "map_to_table/1" do
    map = %{foo: 0, bar: %{baz: %{quux: 0}}}
    expected = [{"bar", [{"baz", [{"quux", 0}]}]}, {"foo", 0}]
    actual = Util.map_to_table(map)
    assert expected == actual
  end
end
