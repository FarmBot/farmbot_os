defmodule Farmbot.ContextTest do
  use ExUnit.Case, async: true
  alias Farmbot.Context
  alias Farmbot.CeleryScript.Ast

  test "creates a new context" do
    ctx = Context.new()
    assert is_map(ctx)
    assert Map.has_key?(ctx, :data_stack)
  end

  test "pushes data onto the `data_stack`" do
    ctx  = Context.new()
    ast  = %Ast{kind: "solve_rubiks_cube", args: %{color: "red"}, body: []}
    next = Context.push_data(ctx, ast)
    assert is_map(next)
    assert is_list(next.data_stack)

    assert Enum.count(next.data_stack) == (Enum.count(ctx.data_stack ) + 1)
  end

  test "Pops data from the `data_stack`" do
    ctx    = Context.new()
    ast_a  = %Ast{kind: "play_video_games", args: %{shape: "blue"}, body: []}
    ast_b  = %Ast{kind: "paint_house",      args: %{},              body: []}
    ctx    = Context.push_data(ctx, ast_a) |> Context.push_data(ast_b)

    {item_b, new_context_1} = Context.pop_data(ctx)
    assert item_b == ast_b

    assert Enum.count(new_context_1.data_stack) == 1

    {item_a, new_context_2} = Context.pop_data(new_context_1)
    assert item_a == ast_a

    assert Enum.count(new_context_2.data_stack) == 0
  end

  test "will not push data onto the data_stack that isnt an Ast Node" do
    ctx = Context.new()
    assert_raise(FunctionClauseError, fn() ->
      almost_ast = %{kind: "some_kind", args: %{tape_player: true}, body: []}
      Context.push_data(ctx, almost_ast)
    end)
  end

  test "errors if nothing on the data stack" do
    ctx = Context.new()
    assert ctx.data_stack == []
    assert_raise MatchError, fn() ->
      {_item, _next} = Context.pop_data(ctx)
    end
  end

  test "only accepts tagged structs as a context" do
    real_ast = %Ast{kind: "this_is_valid", args: %{}, body: []}
    almost_context = Context.new()
      |> Context.push_data(real_ast)
      |> Map.from_struct

    assert is_map(almost_context)
    refute Map.has_key?(almost_context, :__struct__)

    assert_raise FunctionClauseError, fn() ->
      Context.push_data(almost_context, real_ast)
    end

    assert_raise FunctionClauseError, fn() ->
      Context.pop_data(almost_context)
    end
  end
end
