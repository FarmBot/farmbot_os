defmodule FarmbotOS.Lua.ResultTest do
  use ExUnit.Case
  alias FarmbotOS.Lua.Result

  test "unexpected errors" do
    assert {:error, "Lua error"} == Result.new("?")
  end

  test "error parsing" do
    {:error, msg} = Result.parse_error({:lua_error, {:badarg, :+, :_}, :_}, :_)
    expected = "Bad argument for '+': Ensure all values are the correct type."
    assert msg == expected
    {:error, msg} = Result.parse_error({:badmatch, {:error, [], :_}}, :_)
    expected = "Lua code is possibly invalid: []"
    assert msg == expected
    {:error, msg} = Result.parse_error(:function_clause, :_)

    expected =
      "Function clause error. Check number of arguments and their types."

    assert msg == expected
    {:error, msg} = Result.parse_error({:badmatch, {:error, "foo"}}, :_)
    expected = "foo"
    assert msg == expected
  end
end
