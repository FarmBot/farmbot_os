defmodule Farmbot.CeleryScript.Command.RpcOkTest do
  use ExUnit.Case
  alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command

  test "rpc ok" do
    id = "random thing that should be a uuid"
    json = ~s"""
    {
      "kind": "rpc_ok",
      "args": {"label": "#{id}"}
    }
    """
    resp =
      json
      |> Poison.decode!
      |> Ast.parse
      |> Command.do_command
    assert resp.kind == "rpc_ok"
    assert resp.args.label == id
  end
end
