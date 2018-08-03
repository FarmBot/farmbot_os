defmodule Csvm.ASTTest do
  use ExUnit.Case, async: true
  alias Csvm.AST

  @nothing_json "{\"kind\": \"nothing\", \"args\": {}}"
                |> Jason.decode!()
  @nothing_json_with_body "{\"kind\": \"nothing\", \"args\": {}, \"body\":[#{
                            Jason.encode!(@nothing_json)
                          }]}"
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

  test "won't decode ast from bad json" do
    assert_raise RuntimeError, fn ->
      AST.decode(@bad_json)
    end
  end
end
