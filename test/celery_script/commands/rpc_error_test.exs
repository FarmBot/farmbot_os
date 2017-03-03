defmodule Farmbot.CeleryScript.Command.RpcErrorTest do
  use ExUnit.Case
  alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command

  test "rpc ok" do
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
    resp =
      json
      |> Poison.decode!
      |> Ast.parse
      |> Command.do_command
    assert resp.kind == "rpc_error"
    assert resp.args.label == id

    [message] = resp.body
    assert message.kind == "explanation"
    assert message.args.message == error_message
  end
end
