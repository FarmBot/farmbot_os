defmodule Farmbot.CeleryScript.AST.Inspect do
  use ExUnit.Case
  alias Farmbot.CeleryScript.AST

  @nothing_json "{\"kind\": \"nothing\", \"args\": {}}"

  test "Inspects ast node" do
    {:ok, %AST{} = ast} = AST.decode(@nothing_json)
    assert inspect(ast, []) == "#Nothing<[]>"
  end
end
