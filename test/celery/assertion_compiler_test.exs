defmodule FarmbotOS.Celery.AssertionCompilerTest do
  use ExUnit.Case
  use Mimic
  alias FarmbotOS.Celery.Compiler.{Assertion, Scope}
  alias FarmbotOS.Celery.AST

  test "Assertion.assertion/2" do
    scope = Scope.new()

    expect(FarmbotOS.Celery.SysCallGlue, :log_assertion, 1, fn ok?, t, msg ->
      refute ok?
      assert t == "abort"
      assert msg == "[comment] failed to evaluate, aborting"
      :ok
    end)

    expect(FarmbotOS.Celery.Compiler.Lua, :do_lua, 1, fn lua, actual_scope ->
      assert lua == "return false"
      assert actual_scope == scope
      {:error, "intentional failure case"}
    end)

    {result, _} =
      %{
        kind: :assertion,
        args: %{
          lua: "return false",
          assertion_type: "abort",
          _then: %{kind: :nothing, args: %{}}
        },
        comment: "comment"
      }
      |> AST.decode()
      |> Assertion.assertion(scope)
      |> Macro.to_string()
      |> Code.eval_string()

    assert {:error, "intentional failure case"} == result
  end

  test "Assertion Lua is evaluated when the step runs, not at compile time (#1328)" do
    scope = Scope.new()

    test_pid = self()

    stub(FarmbotOS.Celery.Compiler.Lua, :do_lua, fn lua, _scope ->
      send(test_pid, {:do_lua_called, lua})
      {:ok, [true]}
    end)

    stub(FarmbotOS.Celery.SysCallGlue, :log_assertion, fn _, _, _ -> :ok end)

    compiled =
      %{
        kind: :assertion,
        args: %{
          lua: "return true",
          assertion_type: "abort",
          _then: %{kind: :nothing, args: %{}}
        },
        comment: nil
      }
      |> AST.decode()
      |> Assertion.assertion(scope)

    # Compiling the step must not evaluate the Lua...
    refute_received {:do_lua_called, _}

    # ...running it must.
    {result, _} = compiled |> Macro.to_string() |> Code.eval_string()
    assert result == :ok
    assert_received {:do_lua_called, "return true"}
  end
end
