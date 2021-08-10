defmodule FarmbotCeleryScript.LuaTest do
  use ExUnit.Case
  alias FarmbotCeleryScript.Compiler.Lua
  alias FarmbotCeleryScript.Compiler.Scope

  test "conversion of `cs_scope` to luerl params" do
    cs_scope = %Scope{
      declarations: %{
        "parent" => %{x: 1, y: 2, z: 3},
        "nachos" => %{x: 4, y: 5, z: 6}
      }
    }

    result = Lua.do_lua("variables.parent.x", cs_scope)
    expected = {:error, "CeleryScript syscall stubbed: perform_lua\n"}
    assert result == expected
  end
end
