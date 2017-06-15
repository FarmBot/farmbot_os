defmodule Farmbot.CeleryScript.Command.RpcOk do
  @moduledoc """
    RpcOk
  """

  alias      Farmbot.CeleryScript.{Ast, Command}
  alias      Farmbot.Context
  @behaviour Command

  @doc ~s"""
    Return for a valid Rpc Request
      args: %{label: binary},
      body: []
  """
  @spec run(%{label: binary}, [], Context.t) :: Context.t
  def run(%{label: id}, [], context) do
    data = %Ast{kind: "rpc_ok", args: %{label: id}, body: []}
    Farmbot.Context.push_data(context, data)
  end
end
