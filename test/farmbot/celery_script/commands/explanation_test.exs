defmodule Farmbot.CeleryScript.Command.ExplanationTest do
  use ExUnit.Case, async: true
  alias Farmbot.CeleryScript.{Ast, Command}
  alias Command.Explanation
  alias Farmbot.Context

  setup_all do
    ctx = Context.new()
    [cs_context: ctx]
  end

  test "pushes explanation onto the data_stack", %{cs_context: ctx} do
    assert is_map(ctx)
    msg = "the cat spilled the coffee"
    ast = %Ast{kind: "explanation", args: %{message: msg}, body: []}

    next_context = Explanation.run(ast.args, ast.body, ctx)
    assert is_map(next_context)

    assert Enum.count(next_context.data_stack) == (Enum.count(ctx.data_stack) + 1)

    {results, next_context2} = Context.pop_data(next_context)

    assert is_map(next_context2)
    assert Enum.count(next_context2.data_stack) == (Enum.count(next_context.data_stack) - 1)
    assert is_map(results)
    assert results.kind == ast.kind
    assert results.args == ast.args
  end

end
