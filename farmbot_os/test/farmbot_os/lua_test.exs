defmodule FarmbotOS.LuaTest do
  use ExUnit.Case
  use Mimic
  setup :verify_on_exit!
  alias FarmbotOS.Lua

  @tag :capture_log
  test "evaluates Lua" do
    assert Lua.eval_assertion("Returns 'true'", "return true")
    {:error, message1} = Lua.eval_assertion("Returns 'true'", "-1")

    assert message1 == "bad return value from expression evaluation"

    {:error, error} = Lua.eval_assertion("random error", "return (1/0)")
    assert error == :badarith
  end

  test "assertion logs" do
    # Hmmm
    expect(FarmbotCore.LogExecutor, :execute, 1, fn log ->
      assert log.level == "assertion"
      assert log.message == "this is an assertion"
      assert log.meta == %{assertion_passed: true, assertion_type: :assertion}
    end)

    Lua.log_assertion(true, :assertion, "this is an assertion")
  end
end
