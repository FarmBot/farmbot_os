defmodule Farmbot.CeleryScript.ASTTest do
  use ExUnit.Case, async: true
  alias Farmbot.CeleryScript.AST

  @nothing_json "{\"kind\": \"nothing\", \"args\": {}}"
  @bad_json "{\"whoops\": "

  test "decodes ast from json" do
    res = AST.decode(@nothing_json)
    assert match?({:ok, %AST{}}, res)
  end

  test "won't decode ast from bad json" do
    res = AST.decode(@bad_json)
    assert match?({:error, :unknown_binary}, res)
  end
end
