defmodule FarmbotCeleryScript.AssertionCompilerTest do
  use ExUnit.Case
  use Mimic
  alias FarmbotCeleryScript.Compiler.{Assertion, Scope}
  alias FarmbotCeleryScript.AST

  test "Assertion.assertion/2" do
    scope = Scope.new()

    expect(FarmbotCeleryScript.SysCalls, :log_assertion, 1, fn ok?, t, msg ->
      refute ok?
      assert t == "abort"
      assert msg == "[comment] failed to evaluate, aborting"
      :ok
    end)

    expect(FarmbotCeleryScript.Compiler.Lua, :do_lua, 1, fn lua, actual_scope ->
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
end
