defmodule FarmbotOS.Celery.CompilerGroupsTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.Celery.Compiler.{Utils, Scope}

  setup :verify_on_exit!

  test "add_init_logs" do
    scope =
      Scope.new()
      |> Scope.set("__GROUP__", %{current_index: 4, size: 8})

    [header, footer] =
      Utils.add_init_logs([], scope, "test sequence")
      |> Enum.map(fn ast ->
        {fun, _} =
          ast
          |> Macro.to_string()
          |> Code.eval_string()

        fun
      end)

    expect(FarmbotOS.Celery.SysCallGlue, :sequence_init_log, 1, fn log ->
      assert log == "[4/8] Starting test sequence"
      :ok
    end)

    expect(FarmbotOS.Celery.SysCallGlue, :sequence_complete_log, 1, fn log ->
      assert log == "Completed test sequence"
      :ok
    end)

    assert :ok == header.()
    assert :ok == footer.()
  end
end
