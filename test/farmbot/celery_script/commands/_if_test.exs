defmodule Farmbot.CeleryScript.IfTest do
  use ExUnit.Case, async: false
  alias Farmbot.CeleryScript.{Ast, Command, Error}
  alias Command.If
  alias Farmbot.Context

  setup_all do
    ctx = Context.new()
    [cs_context: ctx]
  end

  test "raises when given a bad left hand side", %{cs_context: context} do
    else_ast = %Ast{kind: "nothing", args: %{}, body: []}
    then_ast = %Ast{kind: "nothing", args: %{}, body: []}
    lhs      = "some arbitrary property"
    rhs      = 1234
    op       = ">"
    args     = %{_else: else_ast, _then: then_ast, lhs: lhs, rhs: rhs, op: op}
    ast      = %Ast{kind: "_if", args: args, body: []}

    assert_raise Error, "Got unexpected left hand side of IF: some arbitrary property", fn() ->
      If.run(ast.args, ast.body, context)
    end
  end

  test "raises if bad operator", %{cs_context: context} do
    else_ast = %Ast{kind: "nothing", args: %{}, body: []}
    then_ast = %Ast{kind: "nothing", args: %{}, body: []}
    lhs      = "x"
    rhs      = 1234
    op       = "almost greater than but not really"
    args     = %{_else: else_ast, _then: then_ast, lhs: lhs, rhs: rhs, op: op}
    ast      = %Ast{kind: "_if", args: args, body: []}

    assert_raise Error, "Bad operator in if #{inspect op}", fn() ->
      If.run(ast.args, ast.body, context)
    end
  end

  test "does if with an axis", %{cs_context: context} do
    [100 ,2,3]  = Farmbot.BotState.set_pos(context, 100, 2, 3)
    then_ast    = %Ast{kind: "nothing", args: %{}, body: []}
    else_ast    = %Ast{kind: "this is fake and unsafe", args: %{}, body: []}
    lhs         = "z"
    rhs         = 0
    op          = ">"
    args        = %{_else: else_ast, _then: then_ast, lhs: lhs, rhs: rhs, op: op}
    ast         = %Ast{kind: "_if", args: args, body: []}

    new_context = If.run(ast.args, ast.body, context)
    {results, _new_context2} = Context.pop_data(new_context)

    assert results == then_ast
    refute results == else_ast

  end

  test "does if with a pin", %{cs_context: context} do
    pin_num = 12
    Farmbot.BotState.set_pin_mode(context, pin_num, 1)
    Farmbot.BotState.set_pin_value(context, pin_num, 123)

    then_ast    = %Ast{kind: "nothing", args: %{}, body: []}
    else_ast    = %Ast{kind: "this is fake and unsafe", args: %{}, body: []}
    lhs         = "pin#{pin_num}"
    op          = "<"
    rhs         = 9000
    args        = %{_else: else_ast, _then: then_ast, lhs: lhs, rhs: rhs, op: op}
    ast         = %Ast{kind: "_if", args: args, body: []}

    new_context = If.run(ast.args, ast.body, context)
    {results, _new_context2} = Context.pop_data(new_context)

    assert results == then_ast
    refute results == else_ast
  end

  test "does else if", %{cs_context: context} do
    [100 ,2,3]  = Farmbot.BotState.set_pos(context, 100, 2, 3)
    else_ast    = %Ast{kind: "nothing", args: %{}, body: []}
    then_ast    = %Ast{kind: "this is fake and unsafe", args: %{}, body: []}
    lhs         = "y"
    rhs         = 0
    op          = "is"
    args        = %{_else: else_ast, _then: then_ast, lhs: lhs, rhs: rhs, op: op}
    ast         = %Ast{kind: "_if", args: args, body: []}

    new_context = If.run(ast.args, ast.body, context)
    {results, _new_context2} = Context.pop_data(new_context)

    assert results == else_ast
    refute results == then_ast
  end

    test "does else if with not", %{cs_context: context} do
      [100 ,2,3]  = Farmbot.BotState.set_pos(context, 100, 2, 3)
      else_ast    = %Ast{kind: "nothing", args: %{}, body: []}
      then_ast    = %Ast{kind: "this is fake and unsafe", args: %{}, body: []}
      lhs         = "y"
      rhs         = 2
      op          = "not"
      args        = %{_else: else_ast, _then: then_ast, lhs: lhs, rhs: rhs, op: op}
      ast         = %Ast{kind: "_if", args: args, body: []}

      new_context = If.run(ast.args, ast.body, context)
      {results, _new_context2} = Context.pop_data(new_context)

      assert results == else_ast
      refute results == then_ast
  end

end
