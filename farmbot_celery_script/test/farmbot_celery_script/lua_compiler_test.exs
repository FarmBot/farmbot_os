defmodule FarmbotCeleryScript.LuaTest do
  use ExUnit.Case, async: true
  alias FarmbotCeleryScript.Compiler.Lua

  test "conversion of `better_params` to luerl params" do
    better_params = %{
      "parent" => %{x: 1, y: 2, z: 3},
      "nachos" => %{x: 4, y: 5, z: 6}
    }

    result = Lua.do_lua("variables.parent.x", better_params)
    expected = {:error, "CeleryScript syscall stubbed: raw_lua_eval\n"}
    assert result == expected
  end
end
