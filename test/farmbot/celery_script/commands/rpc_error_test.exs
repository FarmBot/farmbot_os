defmodule Farmbot.CeleryScript.Command.RpcErrorTest do
  use ExUnit.Case
  alias Farmbot.CeleryScript.{Command, Ast}

  setup_all do
    [cs_context: Farmbot.Context.new()]
  end

  test "rpc ok", %{cs_context: context} do
    id = "random thing that should be a uuid"
    error_message = "the world exploded!"
    error_json = ~s"""
    {
      "kind": "explanation",
      "args": {"message": "#{error_message}"}
    }
    """
    json = ~s"""
    {
      "kind": "rpc_error",
      "args": {"label": "#{id}"},
      "body": [#{error_json}]
    }
    """
    ast = json |> Poison.decode! |> Ast.parse
    next_context = Command.do_command(ast, context)

    assert is_map(next_context)
    assert next_context.__struct__ == Farmbot.Context

    {resp, _final_context} = Farmbot.Context.pop_data(next_context)

    assert resp.kind == "rpc_error"
    assert resp.args.label == id

    [message] = resp.body
    assert message.kind == "explanation"
    assert message.args.message == error_message
  end
end
