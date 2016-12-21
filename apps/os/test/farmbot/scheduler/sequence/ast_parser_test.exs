defmodule AstTest do
  use ExUnit.Case, async: false
  # %{"args" => %{"message" => "hello world"},
  #  "body" =>
  # [%{"args" => %{"channel_name" => "toast_error"}, "kind" => "channel"}], "kind" => "send_message"}
  test "parses an ast from a stringed map" do
    test_ast =
      %{"args" => %{"message" => "hello world"},
        "body" =>[],
        "kind" => "send_message"}
    ast = Ast.parse(test_ast)
    assert(ast.args.message == "hello world")
    assert(ast.body == [])
    assert(ast.kind == "send_message")
  end

  test "parses an ast from a stringed map with no body" do
    test_ast =
      %{"args" => %{"coords" => [1,2,3]},
        "kind" => "pickup_truck"}
    ast = Ast.parse(test_ast)
    assert(ast.args.coords == [1,2,3])
    assert(ast.body == [])
    assert(ast.kind == "pickup_truck")
  end

  test "parses an ast from a keyed map" do
    test_ast_a =
      %{args: %{},
        kind: "play_kick_ball"}
    ast_a = Ast.parse(test_ast_a)
    assert(ast_a.args == %{})
    assert(ast_a.body == [])
    assert(ast_a.kind == "play_kick_ball")

    test_ast_b =
      %{args: %{},
        body: [],
        kind: "play_kick_ball"}
    ast_b = Ast.parse(test_ast_b)
    assert(ast_b.args == %{})
    assert(ast_b.body == [])
    assert(ast_b.kind == "play_kick_ball")
  end

  test "creats more ast nodes from the body" do
    test_ast_body_inner = %{
      args: %{},
      body: [],
      kind: "inner_body_node"
    }

    test_ast_body_main = %{
      args: %{},
      body: [test_ast_body_inner, test_ast_body_inner],
      kind: "body_node"
    }

    test_ast_main =
      %{args: %{},
        body: [test_ast_body_main, test_ast_body_inner, test_ast_body_main],
        kind: "play_kick_ball"}
    main_ast = Ast.parse(test_ast_main)
    assert(main_ast.args == %{})
    assert(main_ast.kind == "play_kick_ball")
    body = main_ast.body
    assert(is_list(body))
    assert(Enum.count(body) == 3)

    # there may need to be a protection for a stack overflow here lol
    # if you could somehow make a node that references itself or someting
    # similar to that it would recurse forever
    random_ast_node = Enum.random(body)
    assert(random_ast_node.kind |> is_bitstring)
  end

end
