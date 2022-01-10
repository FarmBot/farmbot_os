defmodule FarmbotOS.Celery.LuaTest do
  use ExUnit.Case
  alias FarmbotOS.Celery.Compiler.Lua
  alias FarmbotOS.Celery.Compiler.Scope

  test "variable lookup" do
    variable = %{"x" => 1000}
    cs_scope = %{declarations: %{"parent" => variable}}
    lookup = Lua.generate_lookup_fn(cs_scope)
    one = lookup.([], :the_state)
    two = lookup.(["parent"], :the_state)
    three = lookup.(["foo", "bar"], :the_state)
    assert one == {[variable], :the_state}
    assert two == {[variable], :the_state}

    assert three == %{
             error: "Invalid input. Please pass 1 variable name (string)."
           }
  end

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
