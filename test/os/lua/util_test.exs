defmodule FarmbotOS.Lua.UtilTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotOS.Lua.Util

  test "map_to_table/1" do
    map = %{foo: 0, bar: %{baz: %{quux: 0}}}
    expected = [{"foo", 0}, {"bar", [{"baz", [{"quux", 0}]}]}]
    actual = Util.map_to_table(map)
    assert expected == actual
  end

  test "table_to_map" do
    table = [
      {"array",
       [
         {1, "One"},
         {2, 2.0},
         {3, "Three"}
       ]},
      {"bool", true},
      {"num", 1.23},
      {"num2", 4.0},
      {"str", "str"},
      {"table",
       [
         {"bool", true},
         {"fn", fn -> :ok end},
         {"num", 1.23},
         {"num2", 4.0},
         {"str", "str"}
       ]}
    ]

    expected = %{
      "bool" => true,
      "num" => 1.23,
      "num2" => 4.0,
      "str" => "str",
      "array" => [
        "One",
        2.0,
        "Three"
      ],
      "table" => %{
        "bool" => true,
        "fn" => "[Lua Function]",
        "num" => 1.23,
        "num2" => 4.0,
        "str" => "str"
      }
    }

    actual = Util.lua_to_elixir(table)
    assert actual == expected
  end
end
