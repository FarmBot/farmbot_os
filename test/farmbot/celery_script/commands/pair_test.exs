defmodule Farmbot.CeleryScript.Command.PairTest do
  use ExUnit.Case, async: true
  alias Farmbot.CeleryScript.{Ast, Command}
  alias Command.Pair
  alias Farmbot.Context

  setup_all do
    ctx = Context.new()
    [cs_context: ctx]
  end

  test "pushes a pair onto the data_stack", %{cs_context: ctx} do
    assert is_map(ctx)
    label = "the_answer_to_the_world"
    value = 42

    ast = %Ast{kind: "pair", args: %{label: label, value: value}, body: []}

    next_context = Pair.run(ast.args, ast.body, ctx)
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
