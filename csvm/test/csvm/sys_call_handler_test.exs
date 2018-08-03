defmodule Csvm.SysCallHandlerTest do
  use ExUnit.Case, async: true
  alias Csvm.{AST, SysCallHandler}

  test "trying to get results before they are ready crashes" do
    Process.flag(:trap_exit, true)

    fun = fn _ ->
      Process.sleep(500)
      :ok
    end

    ast = AST.new(:implode, %{}, [])

    pid = SysCallHandler.apply_sys_call_fun(fun, ast)

    assert_raise RuntimeError, "no results", fn ->
      SysCallHandler.get_results(pid)
    end

    refute Process.alive?(pid)
  end
end
