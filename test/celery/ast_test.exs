defmodule FarmbotOS.Celery.ASTTest do
  use ExUnit.Case
  alias FarmbotOS.Celery.AST

  @nothing_json "{\"kind\": \"nothing\", \"args\": {}}"
                |> Jason.decode!()
  @nothing_json_with_body "{\"kind\": \"nothing\", \"args\": {}, \"body\":[#{Jason.encode!(@nothing_json)}]}"
                          |> Jason.decode!()

  @nothing_json_with_args "{\"kind\": \"nothing\", \"args\": {\"nothing\": \"hello world\"}, \"body\":[]}"
                          |> Jason.decode!()

  @nothing_json_with_cs_args "{\"kind\": \"nothing\", \"args\": {\"nothing\": #{Jason.encode!(@nothing_json)}}, \"body\":[]}"
                             |> Jason.decode!()
  @bad_json "{\"whoops\": "

  test "decodes ast from json" do
    res = AST.decode(@nothing_json)
    assert match?(%AST{}, res)
  end

  test "decodes ast with sub asts in the body" do
    res = AST.decode(@nothing_json_with_body)
    assert match?(%AST{}, res)
  end

  test "decodes ast with sub asts in the args" do
    res = AST.decode(@nothing_json_with_cs_args)
    assert match?(%AST{}, res)
  end

  test "decodes ast with literals in the args" do
    res = AST.decode(@nothing_json_with_args)
    assert match?(%AST{}, res)
  end

  test "decodes already decoded celeryscript" do
    %AST{} = ast = AST.decode(@nothing_json)
    assert ast == AST.decode(ast)
  end

  test "won't decode ast from bad json" do
    assert_raise RuntimeError, fn ->
      AST.decode(@bad_json)
    end
  end

  test "builds a new ast" do
    res = AST.new(:nothing, %{nothing: @nothing_json}, [@nothing_json])
    assert match?(%AST{}, res)
  end

  test "decodes a list" do
    assert AST.decode([]) == []
    nothing = AST.new(:nothing, %{nothing: @nothing_json}, [@nothing_json])
    assert AST.decode([nothing]) == [nothing]
  end
end
