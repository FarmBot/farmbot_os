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
      args: %{label: String.t},
      body: []
  """
  @spec run(%{label: String.t}, []) :: Ast.t
  def run(%{label: id}, []) do
    %Ast{kind: "rpc_ok", args: %{label: id}, body: []}
  end
end
