defmodule Farmbot.CeleryScript.Command.RpcOkTest do
  use ExUnit.Case
  alias Farmbot.CeleryScript.{Command, Ast}

  setup_all do
    [cs_context: Ast.Context.new()]
  end

  test "rpc ok", %{cs_context: context} do
    id = "random thing that should be a uuid"
    json = ~s"""
    {
      "kind": "rpc_ok",
      "args": {"label": "#{id}"}
    }
    """
    ast = json |> Poison.decode! |> Ast.parse
    assert is_map(ast)

    next_context = Command.do_command(ast, context)

    assert is_map(next_context)
    assert next_context.__struct__ == Ast.Context

    {resp, _final_context} = Ast.Context.pop_data(next_context)
    assert resp.kind == "rpc_ok"
    assert resp.args.label == id
  end
end
