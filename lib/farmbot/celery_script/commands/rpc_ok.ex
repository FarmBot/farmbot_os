defmodule Farmbot.CeleryScript.Command.RpcOk do
  @moduledoc """
    RpcOk
  """

  alias Farmbot.CeleryScript.Ast
  alias Farmbot.CeleryScript.Command
  require Logger
  @behaviour Command

  @doc ~s"""
    Return for a valid Rpc Request
      args: %{label: binary},
      body: []
  """
  @spec run(%{label: binary}, [], Ast.context) :: Ast.context
  def run(%{label: id}, [], context) do
    data = %Ast{kind: "rpc_ok", args: %{label: id}, body: []}
    Ast.Context.push_data(data, context)
  end
end
